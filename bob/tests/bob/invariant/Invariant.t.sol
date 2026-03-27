// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StdInvariant } from "forge-std/src/StdInvariant.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { Bob } from "src/types/Bob.sol";

import { Base_Test } from "../Base.t.sol";
import { BobHandler } from "./handlers/BobHandler.sol";
import { BobStore } from "./stores/BobStore.sol";

/// @notice Invariant tests for {SablierBob}.
contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    BobHandler internal handler;
    BobStore internal store;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Warp to Feb 1, 2026 for realistic timestamps.
        vm.warp(FEB_1_2026);

        // Deploy the store and handler.
        store = new BobStore();

        // Collect user addresses for the handler.
        address[4] memory handlerUsers = [
            address(users.alice),
            address(users.eve),
            address(users.depositor),
            address(users.newDepositor)
        ];

        handler = new BobHandler({
            store_: store,
            bob_: bob,
            adapter_: adapter,
            weth_: IERC20(address(weth)),
            wstEth_: wstEth,
            oracle_: oracle,
            comptroller_: address(comptroller),
            users_: handlerUsers
        });

        // Label the contracts.
        vm.label({ account: address(store), newLabel: "BobStore" });
        vm.label({ account: address(handler), newLabel: "BobHandler" });

        // Target the handler for invariant testing.
        targetContract(address(handler));

        // Prevent system addresses from being fuzzed as `msg.sender`.
        excludeSender(address(bob));
        excludeSender(address(adapter));
        excludeSender(address(comptroller));
        excludeSender(address(handler));
        excludeSender(address(store));
        excludeSender(address(weth));
        excludeSender(address(steth));
        excludeSender(address(wstEth));
        excludeSender(address(curvePool));
        excludeSender(address(lidoWithdrawalQueue));
        excludeSender(address(oracle));
    }

    /*//////////////////////////////////////////////////////////////////////////
              GROUP A: NON-ADAPTER SOLVENCY (Inv 3, 5, 8, 60, 61, 62)
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Inv 3: For non-adapter vaults, bob's token balance >= sum of share token supplies.
    function invariant_NonAdapterVaultSolvency() external view {
        uint256 totalShareSupply = 0;
        for (uint256 i = 0; i < store.nonAdapterVaultCount(); ++i) {
            uint256 vaultId = store.nonAdapterVaultIds(i);
            IBobVaultShare shareToken = bob.getShareToken(vaultId);
            totalShareSupply += shareToken.totalSupply();
        }
        assertGe(
            weth.balanceOf(address(bob)),
            totalShareSupply,
            "Inv 3: non-adapter vaults: token.balanceOf(bob) < sum of shareToken.totalSupply()"
        );
    }

    /// @dev Inv 5: Shares are minted 1:1 with deposits on enter.
    function invariant_SharesMinted1To1() external view {
        for (uint256 i = 0; i < store.enterRecordCount(); ++i) {
            BobStore.EnterData memory d = store.getEnterRecord(i);
            assertEq(
                d.shareBalanceAfter - d.shareBalanceBefore,
                d.amount,
                "Inv 5: shares minted != deposit amount"
            );
        }
    }

    /// @dev Inv 8: For non-adapter vaults, share supply == totalDeposited - totalSharesBurned.
    function invariant_NonAdapterTokenConservation() external view {
        for (uint256 i = 0; i < store.nonAdapterVaultCount(); ++i) {
            uint256 vaultId = store.nonAdapterVaultIds(i);
            IBobVaultShare shareToken = bob.getShareToken(vaultId);
            uint256 expectedSupply = store.totalDeposited(vaultId) - store.totalSharesBurned(vaultId);
            assertEq(
                shareToken.totalSupply(),
                expectedSupply,
                "Inv 8: token conservation violated for non-adapter vault"
            );
        }
    }

    /// @dev Inv 60: Redeem is all-or-nothing — user's share balance must be zero after redeem.
    function invariant_RedeemAllOrNothing() external view {
        for (uint256 i = 0; i < store.redeemRecordCount(); ++i) {
            BobStore.RedeemData memory d = store.getRedeemRecord(i);
            assertEq(d.shareBalanceAfter, 0, "Inv 60: user share balance not zero after redeem");
        }
    }

    /// @dev Inv 61: For non-adapter vaults, tokens transferred on redeem == prior share balance.
    function invariant_NonAdapterRedeemTransfersShareBalance() external view {
        for (uint256 i = 0; i < store.redeemRecordCount(); ++i) {
            BobStore.RedeemData memory d = store.getRedeemRecord(i);
            if (d.hasAdapter) continue;
            assertEq(
                d.transferAmount,
                d.shareBalanceBefore,
                "Inv 61: non-adapter redeem transferAmount != prior share balance"
            );
        }
    }

    /// @dev Inv 62: When shares are burned on redeem, a corresponding token transfer occurs.
    function invariant_RedeemBurnsSharesWithTransfer() external view {
        for (uint256 i = 0; i < store.redeemRecordCount(); ++i) {
            BobStore.RedeemData memory d = store.getRedeemRecord(i);
            if (d.shareBalanceBefore > 0) {
                assertGt(
                    d.tokenBalanceUserAfter,
                    d.tokenBalanceUserBefore,
                    "Inv 62: shares burned but user token balance did not increase"
                );
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
              GROUP B: CREATION-TIME PROPERTIES (Inv 65, 66, 68, 69)
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Inv 65: Adapter vault has isStakedInAdapter == true after creation.
    function invariant_AdapterVaultStakedAfterCreation() external view {
        for (uint256 i = 0; i < store.creationRecordCount(); ++i) {
            BobStore.CreationData memory d = store.getCreationRecord(i);
            if (d.hasAdapter) {
                assertTrue(d.isStakedInAdapter, "Inv 65: adapter vault not staked after creation");
            }
        }
    }

    /// @dev Inv 66: Non-adapter vault has isStakedInAdapter == false after creation.
    function invariant_NonAdapterVaultNotStakedAfterCreation() external view {
        for (uint256 i = 0; i < store.creationRecordCount(); ++i) {
            BobStore.CreationData memory d = store.getCreationRecord(i);
            if (!d.hasAdapter) {
                assertFalse(d.isStakedInAdapter, "Inv 66: non-adapter vault staked after creation");
            }
        }
    }

    /// @dev Inv 68: BobVaultShare.VAULT_ID() matches the vault it was deployed for.
    function invariant_ShareTokenVaultIdMatches() external view {
        for (uint256 i = 0; i < store.creationRecordCount(); ++i) {
            BobStore.CreationData memory d = store.getCreationRecord(i);
            IBobVaultShare shareToken = IBobVaultShare(d.shareToken);
            assertEq(shareToken.VAULT_ID(), d.vaultId, "Inv 68: VAULT_ID mismatch");
        }
    }

    /// @dev Inv 69: BobVaultShare.SABLIER_BOB() matches address(bob).
    function invariant_ShareTokenSablierBobMatches() external view {
        for (uint256 i = 0; i < store.creationRecordCount(); ++i) {
            BobStore.CreationData memory d = store.getCreationRecord(i);
            IBobVaultShare shareToken = IBobVaultShare(d.shareToken);
            assertEq(shareToken.SABLIER_BOB(), address(bob), "Inv 69: SABLIER_BOB mismatch");
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
              GROUP C: CROSS-CONTRACT ATOMICITY (Inv 1, 11, 82)
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Inv 1: Broad solvency — non-adapter solvency + adapter distribution cap.
    function invariant_BroadSolvency() external view {
        // Non-adapter solvency: bob holds enough WETH for all non-adapter shares.
        uint256 totalNonAdapterShareSupply = 0;
        for (uint256 i = 0; i < store.nonAdapterVaultCount(); ++i) {
            uint256 vaultId = store.nonAdapterVaultIds(i);
            totalNonAdapterShareSupply += bob.getShareToken(vaultId).totalSupply();
        }
        assertGe(
            weth.balanceOf(address(bob)),
            totalNonAdapterShareSupply,
            "Inv 1: broad solvency - non-adapter WETH insufficient"
        );

        // Adapter solvency: total distributed <= WETH received from unstaking.
        for (uint256 i = 0; i < store.adapterVaultCount(); ++i) {
            uint256 vaultId = store.adapterVaultIds(i);
            uint128 wethReceived = store.unstakeResults(vaultId);
            if (wethReceived == 0) continue;
            uint256 totalDistributed = store.totalRedemptionDistributed(vaultId);
            assertLe(
                totalDistributed,
                wethReceived,
                "Inv 1: broad solvency - adapter WETH distributed exceeds unstaked"
            );
        }
    }

    /// @dev Inv 11: For non-adapter, non-native enters, bob's token balance increases by deposit amount.
    function invariant_EnterTransferMatchesMinting() external view {
        for (uint256 i = 0; i < store.enterRecordCount(); ++i) {
            BobStore.EnterData memory d = store.getEnterRecord(i);
            BobStore.VaultMeta memory meta = store.getVaultMeta(d.vaultId);

            // For non-adapter, non-native enters: verify bob's token balance increased by amount.
            if (!meta.hasAdapter && !d.usedNativeToken) {
                uint256 tokenIncrease = d.tokenBalanceBobAfter - d.tokenBalanceBobBefore;
                assertEq(
                    tokenIncrease,
                    d.amount,
                    "Inv 11: bob token balance increase != deposit amount"
                );
            }

            // For all enters: verify shares minted == amount (also covered by Inv 5).
            uint256 sharesMinted = d.shareBalanceAfter - d.shareBalanceBefore;
            assertEq(sharesMinted, d.amount, "Inv 11: shares minted != deposit amount");
        }
    }

    /// @dev Inv 82: enterWithNativeToken wraps exactly msg.value into shares.
    function invariant_NativeTokenWrapsExactMsgValue() external view {
        for (uint256 i = 0; i < store.enterRecordCount(); ++i) {
            BobStore.EnterData memory d = store.getEnterRecord(i);
            if (!d.usedNativeToken) continue;
            uint256 sharesMinted = d.shareBalanceAfter - d.shareBalanceBefore;
            assertEq(
                sharesMinted,
                d.msgValue,
                "Inv 82: shares minted != msg.value for native token entry"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
              GROUP D: ADAPTER ECONOMICS (Inv 6, 24, 27)
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Inv 6: Yield fees must never exceed yield earned.
    function invariant_YieldFeesNotExceedYield() external view {
        for (uint256 i = 0; i < store.redeemRecordCount(); ++i) {
            BobStore.RedeemData memory d = store.getRedeemRecord(i);
            if (!d.hasAdapter) continue;

            uint256 totalReceived = uint256(d.transferAmount) + uint256(d.feeAmountDeductedFromYield);
            if (totalReceived <= d.shareBalanceBefore) {
                // No yield or negative yield — fee must be zero.
                assertEq(
                    d.feeAmountDeductedFromYield,
                    0,
                    "Inv 6: fee charged on zero/negative yield"
                );
            } else {
                // Yield exists — fee must not exceed the yield portion.
                uint256 yieldAmount = totalReceived - d.shareBalanceBefore;
                assertLe(
                    d.feeAmountDeductedFromYield,
                    yieldAmount,
                    "Inv 6: fee exceeds yield earned"
                );
            }
        }
    }

    /// @dev Inv 24: Total WETH distributed across all redemptions <= wethReceivedAfterUnstaking.
    function invariant_WethDistributedNotExceedUnstaked() external view {
        for (uint256 i = 0; i < store.adapterVaultCount(); ++i) {
            uint256 vaultId = store.adapterVaultIds(i);
            uint128 wethReceived = store.unstakeResults(vaultId);
            if (wethReceived == 0) continue;
            uint256 totalDistributed = store.totalRedemptionDistributed(vaultId);
            assertLe(
                totalDistributed,
                wethReceived,
                "Inv 24: total WETH distributed exceeds wethReceivedAfterUnstaking"
            );
        }
    }

    /// @dev Inv 27: Late depositor must not earn disproportionate yield.
    /// Uses the user's live wstETH captured right before the redeem call (not the unstake-time
    /// snapshot, which can diverge if share transfers move wstETH between snapshot and redeem).
    function invariant_NoDisproportionateYield() external view {
        for (uint256 i = 0; i < store.redeemRecordCount(); ++i) {
            BobStore.RedeemData memory rd = store.getRedeemRecord(i);
            if (!rd.hasAdapter) continue;
            if (rd.transferAmount == 0 && rd.feeAmountDeductedFromYield == 0) continue;

            uint128 totalWeth = store.unstakeResults(rd.vaultId);
            if (totalWeth == 0) continue;

            uint128 totalWstETH = store.snapshotTotalWstETH(rd.vaultId);
            if (totalWstETH == 0) continue;

            // Use the per-redeem wstETH captured right before the redeem call.
            uint256 userWstETH = uint256(rd.userWstETHBeforeRedeem);
            // User's max fair share of WETH (integer division + 1 for rounding tolerance).
            uint256 maxFairShare =
                (userWstETH * uint256(totalWeth) / uint256(totalWstETH)) + 1;
            uint256 totalUserReceived =
                uint256(rd.transferAmount) + uint256(rd.feeAmountDeductedFromYield);
            assertLe(
                totalUserReceived,
                maxFairShare,
                "Inv 27: user received more than proportional WETH share"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
              GROUP E: ADAPTER AGGREGATE (Inv 26)
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Inv 26: After all users redeem, each depositor's wstETH balance is zero.
    function invariant_AllRedeemsClearUserWstETH() external view {
        for (uint256 i = 0; i < store.adapterVaultCount(); ++i) {
            uint256 vaultId = store.adapterVaultIds(i);
            IBobVaultShare shareToken = bob.getShareToken(vaultId);

            // Only check when all shares have been redeemed.
            if (shareToken.totalSupply() > 0) continue;

            address[] memory depositors = store.getVaultDepositors(vaultId);
            for (uint256 j = 0; j < depositors.length; ++j) {
                assertEq(
                    adapter.getYieldBearingTokenBalanceFor(vaultId, depositors[j]),
                    0,
                    "Inv 26: user wstETH not zero after all shares redeemed"
                );
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
              GROUP F: ADDITIONAL LIVE-STATE INVARIANTS (Inv 12, 18, 28, 29, 72)
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Inv 12: No ETH should remain stuck in the SablierBob contract.
    /// SablierBob has no receive()/fallback(), so ETH can only enter via payable functions
    /// (redeem, enterWithNativeToken). Both forward all ETH onward atomically.
    function invariant_NoEthStuckInBob() external view {
        assertEq(
            address(bob).balance,
            0,
            "Inv 12: ETH stuck in SablierBob"
        );
    }

    /// @dev Inv 18: Per-vault share token totalSupply equals the sum of all holder balances.
    /// The handler only creates shares for the 4 users. We also check handler, bob, and adapter
    /// as defense-in-depth (they should always be zero).
    function invariant_ShareTokenTotalSupplyEqualsSumOfBalances() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);
            IBobVaultShare shareToken = bob.getShareToken(vaultId);

            uint256 sum = 0;
            // Sum the 4 known users.
            address[] memory depositors = store.getVaultDepositors(vaultId);
            for (uint256 j = 0; j < depositors.length; ++j) {
                sum += shareToken.balanceOf(depositors[j]);
            }
            // Defense-in-depth: check handler, bob, and adapter (should always be zero).
            sum += shareToken.balanceOf(address(handler));
            sum += shareToken.balanceOf(address(bob));
            sum += shareToken.balanceOf(address(adapter));

            assertEq(
                shareToken.totalSupply(),
                sum,
                "Inv 18: share token totalSupply != sum of holder balances"
            );
        }
    }

    /// @dev Inv 28: _vaultTotalWstETH equals the sum of all _userWstETH for adapter vaults.
    /// Only checked while isStakedInAdapter is true because processRedemption intentionally
    /// deletes per-user wstETH without decrementing the vault total (the total serves as a
    /// snapshot denominator for proportional WETH distribution).
    function invariant_VaultTotalWstETHEqualsSumUserWstETH() external view {
        for (uint256 i = 0; i < store.adapterVaultCount(); ++i) {
            uint256 vaultId = store.adapterVaultIds(i);

            // Only valid while tokens are still staked (before processRedemption runs).
            if (!bob.isStakedInAdapter(vaultId)) continue;

            uint128 vaultTotal = adapter.getTotalYieldBearingTokenBalance(vaultId);
            uint256 sumUsers = 0;
            address[] memory depositors = store.getVaultDepositors(vaultId);
            for (uint256 j = 0; j < depositors.length; ++j) {
                sumUsers += adapter.getYieldBearingTokenBalanceFor(vaultId, depositors[j]);
            }

            assertEq(
                uint256(vaultTotal),
                sumUsers,
                "Inv 28: _vaultTotalWstETH != sum of _userWstETH"
            );
        }
    }

    /// @dev Inv 29: When shares are burned in redeem, _userWstETH is cleared for adapter vaults.
    /// Only checked for users whose current share balance is still zero (confirming they haven't
    /// re-entered the vault since redeeming, which would give them new wstETH).
    function invariant_UserWstETHClearedAfterRedemption() external view {
        for (uint256 i = 0; i < store.redeemRecordCount(); ++i) {
            BobStore.RedeemData memory d = store.getRedeemRecord(i);
            if (!d.hasAdapter) continue;

            // Skip if user has re-entered (received new shares since redeeming).
            BobStore.VaultMeta memory meta = store.getVaultMeta(d.vaultId);
            if (meta.shareToken.balanceOf(d.user) > 0) continue;

            assertEq(
                adapter.getYieldBearingTokenBalanceFor(d.vaultId, d.user),
                0,
                "Inv 29: user wstETH not cleared after redemption"
            );
        }
    }

    /// @dev Inv 72: processRedemption conservation — transferAmount + fee equals the user's
    /// proportional WETH share. Uses the user's live wstETH captured right before the redeem
    /// call (not the unstake-time snapshot, which can diverge if share transfers move wstETH
    /// between snapshot and redeem). Strict equality because transferAmount = userWethShare - fee
    /// in Solidity, so the sum is algebraically exact.
    function invariant_ProcessRedemptionConservation() external view {
        for (uint256 i = 0; i < store.redeemRecordCount(); ++i) {
            BobStore.RedeemData memory rd = store.getRedeemRecord(i);
            if (!rd.hasAdapter) continue;
            if (rd.transferAmount == 0 && rd.feeAmountDeductedFromYield == 0) continue;

            // Need unstake results for this vault to compute expected share.
            uint128 totalWeth = store.unstakeResults(rd.vaultId);
            if (totalWeth == 0) continue;

            // Use the vault-level snapshot total (set before unstaking, never modified after).
            uint256 totalWstETH = uint256(store.snapshotTotalWstETH(rd.vaultId));
            if (totalWstETH == 0) continue;

            // Use the per-redeem wstETH captured right before the redeem call.
            uint256 userWstETH = uint256(rd.userWstETHBeforeRedeem);
            uint256 expectedWethShare = userWstETH * uint256(totalWeth) / totalWstETH;
            uint256 actualTotal = uint256(rd.transferAmount) + uint256(rd.feeAmountDeductedFromYield);

            assertEq(
                actualTotal,
                expectedWethShare,
                "Inv 72: transferAmount + fee != proportional WETH share"
            );
        }
    }
}
