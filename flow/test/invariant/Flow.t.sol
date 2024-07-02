// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Base_Test } from "../Base.t.sol";
import { FlowCreateHandler } from "./handlers/FlowCreateHandler.sol";
import { FlowHandler } from "./handlers/FlowHandler.sol";
import { FlowStore } from "./stores/FlowStore.sol";

/// @notice Common invariant test logic needed across contracts that inherit from {SablierFlow}.
contract Flow_Invariant_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20[] internal assets;
    FlowCreateHandler internal flowCreateHandler;
    FlowHandler internal flowHandler;
    FlowStore internal flowStore;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Declare the default assets.
        assets.push(assetWithoutDecimals);
        assets.push(dai);
        assets.push(usdc);
        assets.push(IERC20(address(usdt)));

        // Deploy and the FlowStore contract.
        flowStore = new FlowStore();

        // Deploy the handlers.
        flowHandler = new FlowHandler({ flowStore_: flowStore, flow_: flow });
        flowCreateHandler = new FlowCreateHandler({ flowStore_: flowStore, flow_: flow, assets_: assets });

        // Label the contracts.
        vm.label({ account: address(flowStore), newLabel: "flowStore" });
        vm.label({ account: address(flowHandler), newLabel: "flowHandler" });
        vm.label({ account: address(flowCreateHandler), newLabel: "flowCreateHandler" });

        // Target the flow handlers for invariant testing.
        targetContract(address(flowHandler));
        targetContract(address(flowCreateHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(flow));
        excludeSender(address(flowStore));
        excludeSender(address(flowHandler));
        excludeSender(address(flowCreateHandler));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev For any stream, `lastTimeUpdate` should never exceed the current block timestamp.
    function invariant_BlockTimestampGeLastTimeUpdate() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            assertGe(
                getBlockTimestamp(),
                flow.getLastTimeUpdate(streamId),
                "Invariant violation: block timestamp < last time update"
            );
        }
    }

    /// @dev For a given asset, the sum of all stream balances normalized to the asset's decimal should never exceed
    /// the asset balance of the flow contract.
    function invariant_ContractBalanceGeStreamBalances() external view {
        // Check the invariant for each asset.
        for (uint256 i = 0; i < assets.length; ++i) {
            contractBalanceGeStreamBalances(assets[i]);
        }
    }

    function contractBalanceGeStreamBalances(IERC20 asset) internal view {
        uint256 contractBalance = asset.balanceOf(address(flow));
        uint128 streamBalancesSumNormalized;

        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            if (flow.getAsset(streamId) == asset) {
                streamBalancesSumNormalized +=
                    getTransferAmount(flow.getBalance(streamId), flow.getAssetDecimals(streamId));
            }
        }

        assertGe(
            contractBalance,
            streamBalancesSumNormalized,
            unicode"Invariant violation: contract balance < Σ stream balances"
        );
    }

    /// @dev For any stream, if debt > 0, then the withdrawable amount should equal the stream balance.
    function invariant_Debt_WithdrawableAmountEqBalance() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.streamDebtOf(streamId) > 0) {
                assertEq(
                    flow.withdrawableAmountOf(streamId),
                    flow.getBalance(streamId),
                    "Invariant violation: withdrawable amount != balance"
                );
            }
        }
    }

    /// @dev If rps > 0, and no additional deposits are made, then the debt should never decrease.
    function invariant_DebtGt0_RpsGt0_DebtIncrease() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.getRatePerSecond(streamId) > 0 && flowHandler.calls("deposit") == 0) {
                assertGe(
                    flow.streamDebtOf(streamId),
                    flowHandler.previousDebtOf(streamId),
                    "Invariant violation: debt should never decrease"
                );
            }
        }
    }

    /// @dev For any stream, the sum of all deposited amounts should always be greater than or equal to the sum of all
    /// withdrawn and refunded amounts.
    function invariant_InflowGeOutflow() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            assertGe(
                flowStore.depositedAmounts(streamId),
                flowStore.refundedAmounts(streamId) + flowStore.withdrawnAmounts(streamId),
                "Invariant violation: deposited amount < refunded amount + withdrawn amount"
            );
        }
    }

    /// @dev The sum of all deposited amounts should always be greater than or equal to the sum of withdrawn and
    /// refunded amounts.
    function invariant_InflowsSumGeOutflowsSum() external view {
        uint256 streamDepositedAmountsSum = flowStore.streamDepositedAmountsSum();
        uint256 streamRefundedAmountsSum = flowStore.streamRefundedAmountsSum();
        uint256 streamWithdrawnAmountsSum = flowStore.streamWithdrawnAmountsSum();

        assertGe(
            streamDepositedAmountsSum,
            streamRefundedAmountsSum + streamWithdrawnAmountsSum,
            "Invariant violation: stream deposited amounts sum < refunded amounts sum + withdrawn amounts sum"
        );
    }

    /// @dev The next stream ID should always be incremented by 1.
    function invariant_NextStreamId() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 nextStreamId = flow.nextStreamId();
            assertEq(nextStreamId, lastStreamId + 1, "Invariant violation: next stream ID not incremented");
        }
    }

    /// @dev If there is no debt and the stream is paused, the withdrawable amount should always be equal to the
    /// remaining amount.
    function invariant_NoDebt_StreamedPaused_WithdrawableAmountEqRemainingAmount() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.isPaused(streamId) && flow.streamDebtOf(streamId) == 0) {
                assertEq(
                    flow.withdrawableAmountOf(streamId),
                    flow.getRemainingAmount(streamId),
                    "Invariant violation: paused stream withdrawable amount != remaining amount"
                );
            }
        }
    }

    /// @dev If there is no debt and the stream is not paused, the withdrawable amount should always be equal to the
    /// sum of remaining amount and recent amount.
    function invariant_NoDebt_WithdrawableAmountEqRecentAmountPlusRemainingAmount() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (!flow.isPaused(streamId) && flow.streamDebtOf(streamId) == 0) {
                assertEq(
                    flow.withdrawableAmountOf(streamId),
                    flow.recentAmountOf(streamId) + flow.getRemainingAmount(streamId),
                    "Invariant violation: withdrawable amount != recent amount + remaining amount"
                );
            }
        }
    }

    /// @dev If rps > 0, no withdraw is made, amount owed (i.e. streamed amount) should never decrease.
    function invariant_RpsGt0_AmountOwedAlwaysIncrease() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.getRatePerSecond(streamId) != 0 && flowHandler.calls("withdrawAt") == 0) {
                assertGe(
                    flow.amountOwedOf(streamId),
                    flowHandler.previousAmountOwedOf(streamId),
                    "Invariant violation: amount owed should be monotonically increasing"
                );
            }
        }
    }

    /// @dev The stream balance should be equal to the sum of the withdrawable amount and the refundable amount.
    function invariant_StreamBalanceEqWithdrawableAmountPlusRefundableAmount() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            assertEq(
                flow.getBalance(streamId),
                flow.withdrawableAmountOf(streamId) + flow.refundableAmountOf(streamId),
                "Invariant violation: stream balance != withdrawable amount + refundable amount"
            );
        }
    }

    /// @dev If the stream is paused, then the rate per second should always be zero.
    function invariant_StreamPaused_RatePerSecondZero() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.isPaused(streamId)) {
                assertEq(
                    flow.getRatePerSecond(streamId),
                    0,
                    "Invariant violation: paused stream with a non-zero rate per second"
                );
            }
        }
    }
}
