// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ChainlinkOracleMock } from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";
import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Bob } from "src/types/Bob.sol";
import { MockWstETH } from "../../mocks/MockWstETH.sol";
import { Store } from "../stores/Store.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @notice Handler for the invariant tests of {SablierBob} contract.
contract BobHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        Store store_,
        ISablierBob bob_,
        ISablierLidoAdapter adapter_,
        IWETH9 weth_,
        MockWstETH wstEth_,
        ChainlinkOracleMock oracle_,
        address comptroller_
    )
        BaseHandler(store_, bob_, adapter_, weth_, wstEth_, oracle_, comptroller_)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createVault(
        uint40 expirySeed,
        uint256 tokenIndex,
        uint256 timeJumpSeed
    )
        external
        instrument("createVault")
        adjustTimestamp(timeJumpSeed)
        useFuzzedToken(tokenIndex)
    {
        // Skip if max vault count is reached.
        if (store.vaultCount() >= MAX_VAULT_COUNT) return;

        // Bound expiry to a reasonable range.
        uint40 expiry = boundUint40(expirySeed, getBlockTimestamp() + 1, getBlockTimestamp() + 60 days);

        // Set target price to be above current oracle price.
        uint128 targetPrice = 2 * uint128(uint256(oracle.price()));

        // Create the vault.
        setMsgSender(address(this));
        uint256 vaultId =
            bob.createVault({ token: currentToken, oracle: oracle, expiry: expiry, targetPrice: targetPrice });

        // Add the vault ID to the store and snapshot its initial adapter state.
        store.pushVaultId(vaultId);
        store.setPrevIsStakedInAdapter(vaultId, bob.isStakedInAdapter(vaultId));
    }

    function enter(
        uint256 vaultIdSeed,
        uint128 amountSeed,
        address newUser,
        uint256 existingUserSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("enter")
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        // Skip if vault is not active.
        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        // Snapshot the vault status before making the call.
        store.setPrevStatus(vaultId, bob.statusOf(vaultId));

        // Pick a user such that 50% chance to reuse an existing depositor.
        address user = _pickUser(vaultId, newUser, existingUserSeed);

        IERC20 token = bob.getUnderlyingToken(vaultId);
        uint128 amount = _boundDepositAmount(amountSeed, token);

        // If token is WETH, then deal ETH and wrap it into WETH.
        if (address(token) == address(weth)) {
            setMsgSender(user);
            vm.deal(user, amount);
            weth.deposit{ value: amount }();
        }
        // Otherwise, deal the token directly to the user.
        else {
            deal({ token: address(token), to: user, give: amount });
            setMsgSender(user);
        }

        token.approve(address(bob), amount);

        bob.enter(vaultId, amount);

        // If this actions makes the vault settled, record the price.
        _recordPriceAtSettlement(vaultId);

        store.addUser(vaultId, user);
        store.addTotalDeposited(vaultId, amount);
    }

    function enterWithNativeToken(
        uint256 vaultIdSeed,
        uint128 amountSeed,
        address newUser,
        uint256 existingUserSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("enterWithNativeToken")
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        // Native token entry only works with WETH vaults.
        if (address(bob.getUnderlyingToken(vaultId)) != address(weth)) return;

        // Skip if vault is not active.
        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        // Snapshot the vault status before making the call.
        store.setPrevStatus(vaultId, bob.statusOf(vaultId));

        // Pick a user such that 50% chance to reuse an existing depositor.
        address user = _pickUser(vaultId, newUser, existingUserSeed);

        uint128 amount = _boundDepositAmount(amountSeed, weth);

        setMsgSender(user);
        vm.deal(user, amount);
        bob.enterWithNativeToken{ value: amount }(vaultId);

        // If this actions makes the vault settled, record the price.
        _recordPriceAtSettlement(vaultId);

        store.addUser(vaultId, user);
        store.addTotalDeposited(vaultId, amount);
    }

    function redeem(
        uint256 vaultIdSeed,
        uint256 userSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("redeem")
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        // Skip if vault is still active.
        if (bob.statusOf(vaultId) == Bob.Status.ACTIVE) return;

        // Pick an existing depositor.
        address[] memory existingUsers = store.getUsers(vaultId);

        // Skip if no users.
        if (existingUsers.length == 0) return;

        address user = existingUsers[userSeed % existingUsers.length];

        uint128 shareBalance = uint128(bob.getShareToken(vaultId).balanceOf(user));

        // Skip if user has no shares.
        if (shareBalance == 0) return;

        // Snapshot the vault status and adapter state before making the call.
        store.setPrevStatus(vaultId, bob.statusOf(vaultId));
        store.setPrevIsStakedInAdapter(vaultId, bob.isStakedInAdapter(vaultId));

        uint256 transferAmount;
        uint256 feeAmount;

        setMsgSender(user);
        if (address(bob.getAdapter(vaultId)) != address(0)) {
            (transferAmount, feeAmount) = bob.redeem(vaultId);
        } else {
            vm.deal(user, BOB_MIN_FEE_WEI);
            // Ignore the fee amount if vault has no adapter.
            (transferAmount,) = bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultId);
        }

        // If this actions makes the vault settled, record the price.
        _recordPriceAtSettlement(vaultId);

        store.addTotalSharesBurned(vaultId, shareBalance);
        store.addTotalWithdrawn(vaultId, transferAmount + feeAmount);
    }

    function syncPriceFromOracle(
        uint256 vaultIdSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("syncPriceFromOracle")
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        // Skip if vault is not active.
        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        // Snapshot the vault status before making the call.
        store.setPrevStatus(vaultId, bob.statusOf(vaultId));

        bob.syncPriceFromOracle(vaultId);

        // Record the settled price if the vault transitioned to settled.
        _recordPriceAtSettlement(vaultId);
    }

    function unstakeTokensViaAdapter(
        uint256 vaultIdSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("unstakeTokensViaAdapter")
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        // Skip if vault has no adapter.
        if (address(bob.getAdapter(vaultId)) == address(0)) return;

        // Skip if vault is still active.
        if (bob.statusOf(vaultId) == Bob.Status.ACTIVE) return;

        // Skip if vault is already unstaked.
        if (!bob.isStakedInAdapter(vaultId)) return;

        // Skip if no one has deposited into this vault.
        if (store.totalDeposited(vaultId) == 0) return;

        // Snapshot the vault status and adapter state before making the call.
        store.setPrevStatus(vaultId, bob.statusOf(vaultId));
        store.setPrevIsStakedInAdapter(vaultId, bob.isStakedInAdapter(vaultId));

        bob.unstakeTokensViaAdapter(vaultId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Bounds the deposit amount to a reasonable range scaled to the token's decimals.
    function _boundDepositAmount(uint128 seed, IERC20 token) private view returns (uint128) {
        uint256 d = IERC20Metadata(address(token)).decimals();

        uint128 minDeposit = uint128(100 * 10 ** d);
        uint128 maxDeposit = uint128(10_000 * 10 ** d);
        return boundUint128(seed, minDeposit, maxDeposit);
    }

    /// @dev A helper function to pick a user such that 50% chance to reuse an existing depositor.
    function _pickUser(uint256 vaultId, address newUser, uint256 existingUserSeed) private view returns (address) {
        address[] memory existingUsers = store.getUsers(vaultId);
        if (existingUserSeed % 2 == 0 && existingUsers.length > 0) {
            return existingUsers[existingUserSeed / 2 % existingUsers.length];
        } else {
            _assumeValidUser(newUser);
            return newUser;
        }
    }
}
