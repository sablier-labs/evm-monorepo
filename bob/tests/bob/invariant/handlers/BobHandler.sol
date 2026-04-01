// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ChainlinkOracleMock } from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";
import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Bob } from "src/types/Bob.sol";
import { MockWstETH } from "./../../mocks/MockWstETH.sol";
import { Constants } from "./../../utils/Constants.sol";
import { BobStore } from "./../stores/BobStore.sol";

/// @notice Handler for the invariant tests of {SablierBob} contract.
contract BobHandler is Constants, StdCheats, BaseUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maximum number of vaults that can be created during invariant runs.
    uint256 internal constant MAX_VAULT_COUNT = 10;

    /// @dev Minimum deposit amount (0.01 ETH).
    uint128 internal constant MIN_DEPOSIT = 1e16;

    /// @dev Maximum deposit amount (100 ETH).
    uint128 internal constant MAX_DEPOSIT = 100e18;

    /// @dev Maps function names to their call counts.
    mapping(string func => uint256 count) public calls;

    /// @dev Total calls across all handler functions.
    uint256 public totalCalls;

    /// @dev Pre-created user addresses.
    address[4] internal USERS;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierBob public bob;
    ISablierLidoAdapter public adapter;
    BobStore public store;
    IERC20 public weth;
    MockWstETH public wstEth;
    ChainlinkOracleMock public oracle;
    address public comptrollerAddr;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Simulates the passage of time. The time jump is kept under 15 days.
    modifier adjustTimestamp(uint256 timeJumpSeed) {
        uint256 timeJump = _bound(timeJumpSeed, 0, 15 days);
        skip(timeJump);
        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory functionName) {
        calls[functionName]++;
        totalCalls++;
        _;
    }

    /// @dev Skip if no vaults exist.
    modifier vaultCountNotZero() {
        if (store.vaultCount() == 0) return;
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        BobStore store_,
        ISablierBob bob_,
        ISablierLidoAdapter adapter_,
        IERC20 weth_,
        MockWstETH wstEth_,
        ChainlinkOracleMock oracle_,
        address comptroller_,
        address[4] memory users_
    ) {
        store = store_;
        bob = bob_;
        adapter = adapter_;
        weth = weth_;
        wstEth = wstEth_;
        oracle = oracle_;
        comptrollerAddr = comptroller_;
        USERS = users_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createVault(bool withAdapter, uint40 expirySeed) external instrument("createVault") {
        // Limit the number of vaults.
        if (store.vaultCount() >= MAX_VAULT_COUNT) return;

        // Bound expiry to a reasonable range from the current timestamp.
        uint40 expiry = boundUint40(expirySeed, getBlockTimestamp() + 10 days, getBlockTimestamp() + 60 days);

        // Toggle the default adapter as comptroller.
        setMsgSender(comptrollerAddr);
        if (withAdapter) {
            bob.setDefaultAdapter(weth, ISablierBobAdapter(address(adapter)));
        } else {
            bob.setDefaultAdapter(weth, ISablierBobAdapter(address(0)));
        }

        // Reset msg.sender to handler for createVault (anyone can create).
        setMsgSender(address(this));

        // Create the vault.
        uint256 vaultId = bob.createVault({ token: weth, oracle: oracle, expiry: expiry, targetPrice: TARGET_PRICE });

        // Snapshot creation-time properties.
        address shareTokenAddr = address(bob.getShareToken(vaultId));
        bool isStaked = bob.isStakedInAdapter(vaultId);

        // Record in store.
        store.pushVaultId(vaultId, withAdapter);
        store.setVaultMeta(
            vaultId,
            BobStore.VaultMeta({ hasAdapter: withAdapter, token: weth, shareToken: IBobVaultShare(shareTokenAddr) })
        );
        store.pushCreationRecord(
            BobStore.CreationData({
                vaultId: vaultId,
                hasAdapter: withAdapter,
                isStakedInAdapter: isStaked,
                shareToken: shareTokenAddr
            })
        );
    }

    function enter(
        uint256 vaultIdSeed,
        uint128 amountSeed,
        uint256 userSeed
    )
        external
        instrument("enter")
        vaultCountNotZero
    {
        // Pick a random vault and user.
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);
        address user = _fuzzUser(userSeed);

        // Skip if vault is not active.
        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        // Bound deposit amount.
        uint128 amount = boundUint128(amountSeed, MIN_DEPOSIT, MAX_DEPOSIT);

        // Deal WETH to user and approve bob.
        deal({ token: address(weth), to: user, give: amount });
        setMsgSender(user);
        weth.approve(address(bob), amount);

        // Snapshot before.
        BobStore.VaultMeta memory meta = store.getVaultMeta(vaultId);
        uint256 shareBalBefore = meta.shareToken.balanceOf(user);
        uint256 tokenBalBobBefore = weth.balanceOf(address(bob));

        // Enter the vault.
        bob.enter(vaultId, amount);

        // Snapshot after.
        uint256 shareBalAfter = meta.shareToken.balanceOf(user);
        uint256 tokenBalBobAfter = weth.balanceOf(address(bob));

        // Record in store.
        store.addDepositor(vaultId, user);
        store.addTotalDeposited(vaultId, amount);
        store.pushEnterRecord(
            BobStore.EnterData({
                user: user,
                vaultId: vaultId,
                amount: amount,
                shareBalanceBefore: shareBalBefore,
                shareBalanceAfter: shareBalAfter,
                tokenBalanceBobBefore: tokenBalBobBefore,
                tokenBalanceBobAfter: tokenBalBobAfter,
                usedNativeToken: false,
                msgValue: 0
            })
        );
    }

    function enterWithNativeToken(
        uint256 vaultIdSeed,
        uint128 amountSeed,
        uint256 userSeed
    )
        external
        instrument("enterWithNativeToken")
        vaultCountNotZero
    {
        // Pick a random vault and user.
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);
        address user = _fuzzUser(userSeed);

        // Skip if vault is not active.
        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        // Bound deposit amount.
        uint128 amount = boundUint128(amountSeed, MIN_DEPOSIT, MAX_DEPOSIT);

        // Snapshot before.
        BobStore.VaultMeta memory meta = store.getVaultMeta(vaultId);
        uint256 shareBalBefore = meta.shareToken.balanceOf(user);
        uint256 tokenBalBobBefore = weth.balanceOf(address(bob));

        // Deal ETH to user and enter with native token.
        // Use hoax (prank + deal) to atomically set msg.sender and fund the user.
        vm.stopPrank();
        vm.deal(user, amount);
        vm.prank(user);
        bob.enterWithNativeToken{ value: amount }(vaultId);

        // Snapshot after.
        uint256 shareBalAfter = meta.shareToken.balanceOf(user);
        uint256 tokenBalBobAfter = weth.balanceOf(address(bob));

        // Record in store.
        store.addDepositor(vaultId, user);
        store.addTotalDeposited(vaultId, amount);
        store.pushEnterRecord(
            BobStore.EnterData({
                user: user,
                vaultId: vaultId,
                amount: amount,
                shareBalanceBefore: shareBalBefore,
                shareBalanceAfter: shareBalAfter,
                tokenBalanceBobBefore: tokenBalBobBefore,
                tokenBalanceBobAfter: tokenBalBobAfter,
                usedNativeToken: true,
                msgValue: amount
            })
        );
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
        // Pick a random vault and user.
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);
        address user = _fuzzUser(userSeed);

        BobStore.VaultMeta memory meta = store.getVaultMeta(vaultId);

        // Settle the vault if still active.
        _settleVault(vaultId);

        // Check user has shares.
        uint128 shareBalance = uint128(meta.shareToken.balanceOf(user));
        if (shareBalance == 0) return;

        // For adapter vaults: snapshot wstETH before redeem auto-unstakes.
        if (meta.hasAdapter && !store.wstETHSnapshotTaken(vaultId)) {
            _snapshotWstETH(vaultId);
        }

        // Snapshot user's token balance and wstETH before redeem.
        uint256 tokenBalBefore = weth.balanceOf(user);
        uint128 userWstETHBefore = meta.hasAdapter ? adapter.getYieldBearingTokenBalanceFor(vaultId, user) : 0;

        // Redeem.
        uint128 transferAmount;
        uint128 feeAmount;
        if (meta.hasAdapter) {
            setMsgSender(user);
            (transferAmount, feeAmount) = bob.redeem(vaultId);
        } else {
            // Non-adapter vaults need msg.value for fee.
            vm.stopPrank();
            vm.deal(user, BOB_MIN_FEE_WEI);
            vm.prank(user);
            (transferAmount, feeAmount) = bob.redeem{ value: BOB_MIN_FEE_WEI }(vaultId);
        }

        // Snapshot after.
        uint256 shareBalAfter = meta.shareToken.balanceOf(user);
        uint256 tokenBalAfter = weth.balanceOf(user);

        // Record in store.
        BobStore.RedeemData memory data = BobStore.RedeemData({
            user: user,
            vaultId: vaultId,
            shareBalanceBefore: shareBalance,
            shareBalanceAfter: shareBalAfter,
            transferAmount: transferAmount,
            feeAmountDeductedFromYield: feeAmount,
            tokenBalanceUserBefore: tokenBalBefore,
            tokenBalanceUserAfter: tokenBalAfter,
            hasAdapter: meta.hasAdapter,
            userWstETHBeforeRedeem: userWstETHBefore
        });
        store.pushRedeemRecord(data);
        store.addTotalSharesBurned(vaultId, shareBalance);

        // Track total WETH distributed for adapter vaults (transferAmount + fee).
        if (meta.hasAdapter) {
            store.addTotalRedemptionDistributed(vaultId, uint256(transferAmount) + uint256(feeAmount));

            // Record unstake results if this was the first redeem that auto-unstaked.
            if (store.unstakeResults(vaultId) == 0) {
                uint128 wethReceived = uint128(adapter.getWethReceivedAfterUnstaking(vaultId));
                store.setUnstakeResults(vaultId, wethReceived);
            }
        }
    }

    function syncPriceFromOracle(uint256 vaultIdSeed) external instrument("syncPriceFromOracle") vaultCountNotZero {
        // Pick a random vault.
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        // Skip if vault is not active.
        if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) return;

        // Anyone can sync.
        bob.syncPriceFromOracle(vaultId);
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
        // Only operate on adapter vaults.
        if (store.adapterVaultCount() == 0) return;

        // Pick a random adapter vault.
        uint256 index = vaultIdSeed % store.adapterVaultCount();
        uint256 vaultId = store.adapterVaultIds(index);

        // Skip if already unstaked.
        if (!bob.isStakedInAdapter(vaultId)) return;

        // Skip if vault has no deposits (unstaking an empty vault reverts).
        IBobVaultShare shareToken = bob.getShareToken(vaultId);
        if (shareToken.totalSupply() == 0) return;

        // Settle the vault if still active.
        _settleVault(vaultId);

        // Snapshot wstETH balances before unstaking.
        if (!store.wstETHSnapshotTaken(vaultId)) {
            _snapshotWstETH(vaultId);
        }

        // Unstake.
        setMsgSender(address(this));
        bob.unstakeTokensViaAdapter(vaultId);

        // Record WETH received.
        uint128 wethReceived = uint128(adapter.getWethReceivedAfterUnstaking(vaultId));
        store.setUnstakeResults(vaultId, wethReceived);
    }

    function requestLidoWithdrawal(
        uint256 vaultIdSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("requestLidoWithdrawal")
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        // Only operate on adapter vaults.
        if (store.adapterVaultCount() == 0) return;

        // Pick a random adapter vault.
        uint256 index = vaultIdSeed % store.adapterVaultCount();
        uint256 vaultId = store.adapterVaultIds(index);

        // Skip if already unstaked.
        if (!bob.isStakedInAdapter(vaultId)) return;

        // Skip if vault has no deposits.
        IBobVaultShare shareToken = bob.getShareToken(vaultId);
        if (shareToken.totalSupply() == 0) return;

        // Skip if Lido withdrawal already requested for this vault.
        if (store.lidoWithdrawalRequested(vaultId)) return;

        // Settle the vault (requestLidoWithdrawal requires non-ACTIVE).
        _settleVault(vaultId);

        // Request Lido withdrawal as comptroller.
        setMsgSender(comptrollerAddr);
        adapter.requestLidoWithdrawal(vaultId);
        store.setLidoWithdrawalRequested(vaultId);
    }

    function transferShares(
        uint256 vaultIdSeed,
        uint256 fromUserSeed,
        uint256 toUserSeed,
        uint128 amountSeed
    )
        external
        instrument("transferShares")
        vaultCountNotZero
    {
        // Pick a random vault and two different users.
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);
        address from = _fuzzUser(fromUserSeed);
        address to = _fuzzUser(toUserSeed);

        // Users must be different.
        if (from == to) return;

        BobStore.VaultMeta memory meta = store.getVaultMeta(vaultId);

        // Check sender has shares.
        uint256 shareBalance = meta.shareToken.balanceOf(from);
        if (shareBalance == 0) return;

        // Bound transfer amount.
        uint128 amount = boundUint128(amountSeed, 1, uint128(shareBalance));

        // Transfer shares. Use try/catch because adapter vaults revert when the
        // proportional wstETH transfer rounds to zero (M-3 fix).
        setMsgSender(from);
        try IERC20(address(meta.shareToken)).transfer(to, amount) {
            // Track the recipient as a depositor (they now hold shares).
            store.addDepositor(vaultId, to);
        } catch {
            // Transfer reverted (e.g., wstETH rounds to zero for tiny amounts). Skip.
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Returns a random vault ID from the store.
    function _fuzzVaultId(uint256 seed) private view returns (uint256) {
        uint256 index = seed % store.vaultCount();
        return store.vaultIds(index);
    }

    /// @dev Returns a random user address.
    function _fuzzUser(uint256 seed) private view returns (address) {
        return USERS[seed % USERS.length];
    }

    /// @dev Settles a vault by temporarily raising oracle price to target.
    ///      For adapter vaults, also simulates yield by lowering the wstETH exchange rate
    ///      (each wstETH unwraps to more stETH, creating a net gain).
    function _settleVault(uint256 vaultId) private {
        if (bob.statusOf(vaultId) == Bob.Status.ACTIVE) {
            oracle.setPrice(TARGET_PRICE);
            setMsgSender(address(this));
            bob.syncPriceFromOracle(vaultId);
            oracle.setPrice(CURRENT_PRICE);
        }

        // Simulate yield for adapter vaults: lower exchange rate so unwrap gives more stETH.
        // Default rate is 0.9e18. Lowering to 0.8e18 means each wstETH = 1/0.8 = 1.25 stETH
        // instead of 1/0.9 = 1.11 stETH, creating ~12.5% yield.
        BobStore.VaultMeta memory meta = store.getVaultMeta(vaultId);
        if (meta.hasAdapter && bob.isStakedInAdapter(vaultId)) {
            wstEth.setExchangeRate(UD60x18.wrap(0.8e18));
        }
    }

    /// @dev Snapshots wstETH balances for all depositors of a vault.
    function _snapshotWstETH(uint256 vaultId) private {
        store.setWstETHSnapshotTaken(vaultId);

        uint128 totalWstETH = adapter.getTotalYieldBearingTokenBalance(vaultId);
        store.setSnapshotTotalWstETH(vaultId, totalWstETH);

        address[] memory depositors = store.getVaultDepositors(vaultId);
        for (uint256 i = 0; i < depositors.length; ++i) {
            uint128 userWstETH = adapter.getYieldBearingTokenBalanceFor(vaultId, depositors[i]);
            store.setSnapshotUserWstETH(vaultId, depositors[i], userWstETH);
        }
    }
}
