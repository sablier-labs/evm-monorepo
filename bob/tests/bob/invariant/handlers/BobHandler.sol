// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ChainlinkOracleMock } from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
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
        IERC20 weth_,
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
        bool withAdapter,
        uint40 expirySeed,
        uint256 tokenIndex
    )
        external
        instrument("createVault")
        useFuzzedToken(tokenIndex)
    {
        _recordStatuses();

        if (store.vaultCount() >= MAX_VAULT_COUNT) return;

        uint40 expiry = boundUint40(expirySeed, getBlockTimestamp() + 10 days, getBlockTimestamp() + 60 days);

        // Adapter is only supported for WETH.
        bool useAdapter = withAdapter && address(currentToken) == address(weth);

        setMsgSender(comptroller);
        if (useAdapter) {
            bob.setDefaultAdapter(weth, ISablierBobAdapter(address(adapter)));
        } else {
            bob.setDefaultAdapter(weth, ISablierBobAdapter(address(0)));
        }

        setMsgSender(address(this));

        uint256 vaultId =
            bob.createVault({ token: currentToken, oracle: oracle, expiry: expiry, targetPrice: TARGET_PRICE });

        store.pushVaultId(vaultId);
        store.setPrevStatus(vaultId, uint8(bob.statusOf(vaultId)));
        store.setPrevIsStakedInAdapter(vaultId, bob.isStakedInAdapter(vaultId));
    }

    function enter(
        uint256 vaultIdSeed,
        uint128 amountSeed,
        address user
    )
        external
        instrument("enter")
        checkUser(user)
        vaultCountNotZero
    {
        _recordStatuses();

        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        IERC20 token = bob.getUnderlyingToken(vaultId);
        uint128 amount = _boundDepositAmount(amountSeed, token);

        deal({ token: address(token), to: user, give: amount });
        setMsgSender(user);
        token.approve(address(bob), amount);

        bob.enter(vaultId, amount);

        store.addUser(vaultId, user);
        store.addTotalDeposited(vaultId, amount);
    }

    function enterWithNativeToken(
        uint256 vaultIdSeed,
        uint128 amountSeed,
        address user
    )
        external
        instrument("enterWithNativeToken")
        checkUser(user)
        vaultCountNotZero
    {
        _recordStatuses();

        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        // Native token entry only works with WETH vaults.
        if (address(bob.getUnderlyingToken(vaultId)) != address(weth)) return;

        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        uint128 amount = _boundDepositAmount(amountSeed, weth);

        vm.stopPrank();
        vm.deal(user, amount);
        vm.prank(user);
        bob.enterWithNativeToken{ value: amount }(vaultId);

        store.addUser(vaultId, user);
        store.addTotalDeposited(vaultId, amount);
    }

    function redeem(
        uint256 vaultIdSeed,
        address user,
        uint256 timeJumpSeed
    )
        external
        instrument("redeem")
        checkUser(user)
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        _recordStatuses();

        uint256 vaultId = _fuzzVaultId(vaultIdSeed);
        bool hasAdapterVault = address(bob.getAdapter(vaultId)) != address(0);

        _settleVault(vaultId);

        uint128 shareBalance = uint128(bob.getShareToken(vaultId).balanceOf(user));
        if (shareBalance == 0) return;

        uint128 transferAmount;
        uint128 feeAmount;
        if (hasAdapterVault) {
            setMsgSender(user);
            (transferAmount, feeAmount) = bob.redeem(vaultId);
        } else {
            vm.stopPrank();
            vm.deal(user, BOB_MIN_FEE_WEI);
            vm.prank(user);
            (transferAmount, feeAmount) = bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultId);
        }

        store.addTotalSharesBurned(vaultId, shareBalance);
        store.addTotalWithdrawn(vaultId, uint256(transferAmount) + uint256(feeAmount));
    }

    function syncPriceFromOracle(uint256 vaultIdSeed) external instrument("syncPriceFromOracle") vaultCountNotZero {
        _recordStatuses();

        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        bob.syncPriceFromOracle(vaultId);
    }

    function transferShares(
        uint256 vaultIdSeed,
        address from,
        address to,
        uint128 amountSeed
    )
        external
        instrument("transferShares")
        checkUsers(from, to)
        vaultCountNotZero
    {
        _recordStatuses();

        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        IBobVaultShare shareToken = bob.getShareToken(vaultId);
        uint256 shareBalance = shareToken.balanceOf(from);
        if (shareBalance == 0) return;

        uint128 amount = boundUint128(amountSeed, 1, uint128(shareBalance));

        // Use try/catch because adapter vaults revert when the proportional wstETH transfer rounds to zero (M-3 fix).
        setMsgSender(from);
        try IERC20(address(shareToken)).transfer(to, amount) {
            store.addUser(vaultId, to);
        } catch { }
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
        _recordStatuses();

        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        if (address(bob.getAdapter(vaultId)) == address(0)) return;
        if (!bob.isStakedInAdapter(vaultId)) return;
        if (bob.getShareToken(vaultId).totalSupply() == 0) return;

        _settleVault(vaultId);

        setMsgSender(address(this));
        bob.unstakeTokensViaAdapter(vaultId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Bounds the deposit amount to a reasonable range scaled to the token's decimals.
    function _boundDepositAmount(uint128 seed, IERC20 token) private view returns (uint128) {
        uint8 d = IERC20Metadata(address(token)).decimals();
        uint128 minDeposit = uint128(10 ** (d - 2));
        uint128 maxDeposit = uint128(100 * 10 ** uint256(d));
        return boundUint128(seed, minDeposit, maxDeposit);
    }
}
