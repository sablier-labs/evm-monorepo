// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20Mock } from "@sablier/evm-utils/src/mocks/erc20/ERC20Mock.sol";
import { StdInvariant } from "forge-std/src/StdInvariant.sol";
import { Bob } from "src/types/Bob.sol";

import { Base_Test } from "../Base.t.sol";
import { BobHandler } from "./handlers/BobHandler.sol";
import { LidoAdapterHandler } from "./handlers/LidoAdapterHandler.sol";
import { Store } from "./stores/Store.sol";

/// @notice Invariant tests for {SablierBob} and {SablierLidoAdapter}.
contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    BobHandler internal bobHandler;
    LidoAdapterHandler internal lidoAdapterHandler;
    Store internal store;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Warp to Feb 1, 2026 for realistic timestamps.
        vm.warp(FEB_1_2026);

        // Deploy 13 tokens: ERC20Mock for decimals 6-17, plus WETH for decimal 18.
        IERC20[] memory tokenList = new IERC20[](13);
        for (uint8 d = 6; d <= 17; ++d) {
            string memory name = string.concat("Token", vm.toString(d));
            string memory symbol = string.concat("T", vm.toString(d));
            tokenList[d - 6] = IERC20(address(new ERC20Mock(name, symbol, d)));
            vm.label(address(tokenList[d - 6]), symbol);
        }
        tokenList[12] = IERC20(address(weth));

        // Deploy the store and handlers.
        store = new Store(tokenList);

        bobHandler = new BobHandler({
            store_: store,
            bob_: bob,
            adapter_: adapter,
            weth_: IERC20(address(weth)),
            wstEth_: wstEth,
            oracle_: oracle,
            comptroller_: address(comptroller)
        });

        lidoAdapterHandler = new LidoAdapterHandler({
            store_: store,
            bob_: bob,
            adapter_: adapter,
            weth_: IERC20(address(weth)),
            wstEth_: wstEth,
            oracle_: oracle,
            comptroller_: address(comptroller)
        });

        // Label the contracts.
        vm.label({ account: address(store), newLabel: "Store" });
        vm.label({ account: address(bobHandler), newLabel: "BobHandler" });
        vm.label({ account: address(lidoAdapterHandler), newLabel: "LidoAdapterHandler" });

        // Target both handlers for invariant testing.
        targetContract(address(bobHandler));
        targetContract(address(lidoAdapterHandler));

        // Prevent system addresses from being fuzzed as `msg.sender`.
        excludeSender(address(bob));
        excludeSender(address(adapter));
        excludeSender(address(comptroller));
        excludeSender(address(bobHandler));
        excludeSender(address(lidoAdapterHandler));
        excludeSender(address(store));
        excludeSender(address(weth));
        excludeSender(address(steth));
        excludeSender(address(wstEth));
        excludeSender(address(curvePool));
        excludeSender(address(lidoWithdrawalQueue));
        excludeSender(address(oracle));
        for (uint256 i = 0; i < 12; ++i) {
            excludeSender(address(tokenList[i]));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INVARIANTS - BOB
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The next vault ID should always be incremented by 1.
    function invariant_NextVaultId() external view {
        assertEq(
            bob.nextVaultId(),
            store.vaultCount() + 1,
            "Invariant violation: nextVaultId != number of vaults created + 1"
        );
    }

    /// @dev For a given token, across all vaults without adapter, Σ deposits = Σ share supply + Σ tokens redeemed.
    function invariant_DepositsEqualsShareSupplyPlusRedeemed() external view {
        IERC20[] memory tokenList = store.getTokens();
        for (uint256 t = 0; t < tokenList.length; ++t) {
            uint256 totalDeposits;
            uint256 totalShareSupply;
            uint256 totalRedeemed;

            for (uint256 i = 0; i < store.vaultCount(); ++i) {
                uint256 vaultId = store.vaultIds(i);

                // Since the invariant only holds true for vaults without adapter, skip if vault has an adapter.
                if (address(bob.getAdapter(vaultId)) != address(0)) continue;

                // Skip if vault's underlying token is not the token being tested.
                if (bob.getUnderlyingToken(vaultId) != tokenList[t]) continue;

                // Add to the total deposits, share supply, and redeemed tokens.
                totalDeposits += store.totalDeposited(vaultId);
                totalShareSupply += bob.getShareToken(vaultId).totalSupply();
                totalRedeemed += store.totalSharesBurned(vaultId);
            }

            assertEq(
                totalDeposits,
                totalShareSupply + totalRedeemed,
                "Invariant violation: deposits != share supply + tokens redeemed (non-adapter)"
            );
        }
    }

    /// @dev For a given token, token balance of Bob should equal Σ deposit amount across vaults without adapter + Σ
    /// token received from adapter - Σ withdrawn amount by users across all vaults.
    function invariant_ConservationOfTokenBalance() external view {
        IERC20[] memory tokenList = store.getTokens();
        for (uint256 t = 0; t < tokenList.length; ++t) {
            uint256 totalDepositAmountInVaultsWithoutAdapter;
            uint256 totalReceivedFromAdapter;
            uint256 totalWithdrawn;

            IERC20 token = tokenList[t];
            for (uint256 i = 0; i < store.vaultCount(); ++i) {
                uint256 vaultId = store.vaultIds(i);

                // Skip if vault's underlying token is not the token being tested.
                if (bob.getUnderlyingToken(vaultId) != token) continue;

                // If vault has no adapter, add to the total deposit amount.
                if (address(bob.getAdapter(vaultId)) == address(0)) {
                    totalDepositAmountInVaultsWithoutAdapter += store.totalDeposited(vaultId);
                }
                // Otherwise, add to the total amount received from adapter.
                else {
                    totalReceivedFromAdapter += adapter.getWethReceivedAfterUnstaking(vaultId);
                }
                totalWithdrawn += store.totalWithdrawn(vaultId);
            }

            assertEq(
                token.balanceOf(address(bob)),
                totalDepositAmountInVaultsWithoutAdapter + totalReceivedFromAdapter - totalWithdrawn,
                "Invariant violation: token balance != deposits (non-adapter) + received from adapter - withdrawn"
            );
        }
    }

    /// @dev The value of isStakedInAdapter can never change from false to true.
    function invariant_IsStakedInAdapterMonotonicity() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // If previous value of isStakedInAdapter was false, current value must be false.
            if (!store.prevIsStakedInAdapter(vaultId)) {
                assertFalse(
                    bob.isStakedInAdapter(vaultId), "Invariant violation: isStakedInAdapter changed from false to true"
                );
            }
        }
    }

    /// @dev For a given vault, total supply of share tokens should equal Σ deposits - Σ shares burned.
    function invariant_ShareTokenConservation() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);
            assertEq(
                bob.getShareToken(vaultId).totalSupply(),
                store.totalDeposited(vaultId) - store.totalSharesBurned(vaultId),
                "Invariant violation: share token supply != deposits - burned"
            );
        }
    }

    /// @dev For vaults with adapter, amount received from adapter should be >= the sum of transfer amounts and fees for
    /// during redemption for each user.
    function invariant_TokenSolvencyForVaultsWithAdapter() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // Skip if vault has no adapter.
            if (address(bob.getAdapter(vaultId)) == address(0)) continue;

            // Skip if tokens are still staked.
            if (bob.isStakedInAdapter(vaultId)) continue;

            assertGe(
                adapter.getWethReceivedAfterUnstaking(vaultId),
                store.totalWithdrawn(vaultId),
                "Invariant violation: amount received from adapter < sum of transfer amounts and fees during redemption"
            );
        }
    }

    /// @dev For an active vault, lastSyncedPrice < targetPrice and block.timestamp < expiry.
    function invariant_ActiveVaultConditions() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // Skip if vault is not active.
            if (bob.statusOf(vaultId) != Bob.Status.ACTIVE) continue;

            assertLt(
                bob.getLastSyncedPrice(vaultId),
                bob.getTargetPrice(vaultId),
                "Invariant violation: lastSyncedPrice >= targetPrice"
            );
            assertLt(getBlockTimestamp(), bob.getExpiry(vaultId), "Invariant violation: block.timestamp >= expiry");
        }
    }

    /// @dev For an expired vault, block.timestamp >= expiry.
    function invariant_ExpiredVaultConditions() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // Skip if vault is not expired.
            if (bob.statusOf(vaultId) != Bob.Status.EXPIRED) continue;

            assertGe(getBlockTimestamp(), bob.getExpiry(vaultId), "Invariant violation: block.timestamp < expiry");
        }
    }

    /// @dev For a settled vault, lastSyncedPrice >= targetPrice and block.timestamp < expiry.
    function invariant_SettledVaultConditions() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // Skip if vault is not settled.
            if (bob.statusOf(vaultId) != Bob.Status.SETTLED) continue;

            assertGe(
                bob.getLastSyncedPrice(vaultId),
                bob.getTargetPrice(vaultId),
                "Invariant violation: lastSyncedPrice < targetPrice"
            );
            assertLt(getBlockTimestamp(), bob.getExpiry(vaultId), "Invariant violation: block.timestamp >= expiry");
        }
    }

    /// @dev State transitions:
    /// - An expired vault cannot transition to active or settled.
    /// - A settled vault cannot transition to active.
    function invariant_StateTransitions() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // Get the current status of the vault.
            Bob.Status currentStatus = bob.statusOf(vaultId);

            // Get previous status of the vault.
            Bob.Status prevStatus = Bob.Status(store.prevStatus(vaultId));

            // If the previous status was expired, the current status must be expired.
            if (prevStatus == Bob.Status.EXPIRED) {
                assertNotEq(currentStatus, Bob.Status.ACTIVE, "Invariant violation: EXPIRED -> ACTIVE");
                assertNotEq(currentStatus, Bob.Status.SETTLED, "Invariant violation: EXPIRED -> SETTLED");
            }

            // If the previous status was settled, the current status must not be active.
            if (prevStatus == Bob.Status.SETTLED) {
                assertNotEq(currentStatus, Bob.Status.ACTIVE, "Invariant violation: SETTLED -> ACTIVE");
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INVARIANTS - LIDO ADAPTER
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The wstETH balance of the adapter should equal the sum of wstETH balances of staked vaults.
    function invariant_ConservationOfWstethBalance() external view {
        uint256 totalVaultWstETH;
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // Skip if the vault has no adapter.
            if (address(bob.getAdapter(vaultId)) == address(0)) continue;

            // Skip if vault has already been unstaked.
            if (!bob.isStakedInAdapter(vaultId)) continue;

            // Skip if Lido withdrawal is requested.
            if (adapter.getLidoWithdrawalRequestIds(vaultId).length > 0) continue;

            totalVaultWstETH += adapter.getTotalYieldBearingTokenBalance(vaultId);
        }

        assertEq(
            wstEth.balanceOf(address(adapter)),
            totalVaultWstETH,
            "Invariant violation: wstETH balance != sum of staked vault wstETH"
        );
    }

    /// @dev For vaults with adapter,
    /// - if isStakedInAdapter = true, vault total wstETH should equal the sum of wstETH balances of each user.
    /// - if isStakedInAdapter = false, vault total wstETH should be greater than or equal to the sum of wstETH balances
    /// of each user.
    function invariant_VaultTotalWstethEqSumUserWstethWhenStaked() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // Skip if vault has no adapter.
            if (address(bob.getAdapter(vaultId)) == address(0)) continue;

            uint256 cumulativeUserWstETHBalance = 0;
            address[] memory depositors = store.getUsers(vaultId);
            for (uint256 j = 0; j < depositors.length; ++j) {
                cumulativeUserWstETHBalance += adapter.getYieldBearingTokenBalanceFor(vaultId, depositors[j]);
            }

            if (bob.isStakedInAdapter(vaultId)) {
                assertEq(
                    adapter.getTotalYieldBearingTokenBalance(vaultId),
                    cumulativeUserWstETHBalance,
                    "Invariant violation: _vaultTotalWstETH != sum of _userWstETH for staked vault"
                );
            } else {
                assertGe(
                    adapter.getTotalYieldBearingTokenBalance(vaultId),
                    cumulativeUserWstETHBalance,
                    "Invariant violation: _vaultTotalWstETH < sum of _userWstETH for unstaked vault"
                );
            }
        }
    }

    /// @dev If a user's share balance is 0, `getYieldBearingTokenBalanceFor` should return 0. If the user has share
    /// balance > 0, `getYieldBearingTokenBalanceFor` > 0.
    function invariant_SynchronizationBetweenSharesAndWstethBalance() external view {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);

            // Skip if vault has no adapter.
            if (address(bob.getAdapter(vaultId)) == address(0)) continue;

            address[] memory depositors = store.getUsers(vaultId);
            for (uint256 j = 0; j < depositors.length; ++j) {
                if (bob.getShareToken(vaultId).balanceOf(depositors[j]) > 0) {
                    assertGt(
                        adapter.getYieldBearingTokenBalanceFor(vaultId, depositors[j]),
                        0,
                        "Invariant violation: user has shares but wstETH = 0"
                    );
                } else {
                    assertEq(
                        adapter.getYieldBearingTokenBalanceFor(vaultId, depositors[j]),
                        0,
                        "Invariant violation: user has 0 shares but wstETH > 0"
                    );
                }
            }
        }
    }
}
