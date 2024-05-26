// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Invariant_Test } from "./Invariant.t.sol";
import { FlowCreateHandler } from "./handlers/FlowCreateHandler.sol";
import { FlowHandler } from "./handlers/FlowHandler.sol";
import { FlowStore } from "./stores/FlowStore.sol";

/// @notice Common invariant test logic needed across contracts that inherit from {SablierFlow}.
contract Flow_Invariant_Test is Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    FlowCreateHandler internal flowCreateHandler;
    FlowHandler internal flowHandler;
    FlowStore internal flowStore;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Invariant_Test.setUp();

        // Deploy and the FlowStore contract.
        flowStore = new FlowStore();

        // Deploy the handlers.
        flowHandler = new FlowHandler({ asset_: dai, flowStore_: flowStore, flow_: flow });
        flowCreateHandler = new FlowCreateHandler({ asset_: dai, flowStore_: flowStore, flow_: flow });

        // Label the contracts.
        vm.label({ account: address(flowStore), newLabel: "flowStore" });
        vm.label({ account: address(flowHandler), newLabel: "flowHandler" });
        vm.label({ account: address(flowCreateHandler), newLabel: "flowCreateHandler" });

        // Target the flow handlers for invariant testing.
        targetContract(address(flowHandler));
        targetContract(address(flowCreateHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(flowStore));
        excludeSender(address(flowHandler));
        excludeSender(address(flowCreateHandler));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    function invariant_BlockTimestampGeLastTimeUpdate() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            assertGe(
                uint40(block.timestamp),
                flow.getLastTimeUpdate(streamId),
                "Invariant violation: block timestamp < last time update"
            );
        }
    }

    /// @dev The sum of all stream balances for a specific asset should be less than or equal to the contract
    /// `ERC20.balanceOf`.
    function invariant_ContractBalanceGeStreamBalances() external view {
        uint256 contractBalance = dai.balanceOf(address(flow));

        uint256 lastStreamId = flowStore.lastStreamId();
        uint256 streamBalancesSumNormalized;
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            streamBalancesSumNormalized += uint256(normalizeStreamBalance(streamId));
        }

        assertGe(
            contractBalance,
            streamBalancesSumNormalized,
            unicode"Invariant violation: contract balanceOf < Σ stream balances"
        );
    }

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

    function invariant_DepositAmountsSumGeExtractedAmountsSum() external view {
        uint256 streamDepositedAmountsSum = flowStore.streamDepositedAmountsSum();
        uint256 streamExtractedAmountsSum = flowStore.streamExtractedAmountsSum();

        assertGe(
            streamDepositedAmountsSum,
            streamExtractedAmountsSum,
            "Invariant violation: stream deposited amounts sum < stream extracted amounts sum"
        );
    }

    function invariant_DepositedAmountsSumGeExtractedAmountsSum() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            assertGe(
                flowStore.depositedAmounts(streamId),
                flowStore.extractedAmounts(streamId),
                "Invariant violation: deposited amount < extracted amount"
            );
        }

        uint256 streamDepositedAmountsSum = flowStore.streamDepositedAmountsSum();
        uint256 streamExtractedAmountsSum = flowStore.streamExtractedAmountsSum();

        assertGe(
            streamDepositedAmountsSum,
            streamExtractedAmountsSum,
            "Invariant violation: stream deposited amounts sum < stream extracted amounts sum"
        );
    }

    function invariant_NextStreamId() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 nextStreamId = flow.nextStreamId();
            assertEq(nextStreamId, lastStreamId + 1, "Invariant violation: next stream id not incremented");
        }
    }

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

    function invariant_NoDebt_WithdrawableAmountEqStreamedAmountPlusRemainingAmount() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (!flow.isPaused(streamId) && flow.streamDebtOf(streamId) == 0) {
                assertEq(
                    flow.withdrawableAmountOf(streamId),
                    flow.streamedAmountOf(streamId) + flow.getRemainingAmount(streamId),
                    "Invariant violation: withdrawable amount != streamed amount + remaining amount"
                );
            }
        }
    }

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

    function invariant_StreamBalanceGeRefundableAmount() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (!flow.isPaused(streamId)) {
                assertGe(
                    flow.getBalance(streamId),
                    flow.refundableAmountOf(streamId),
                    "Invariant violation: stream balance < refundable amount"
                );
            }
        }
    }

    function invariant_StreamBalanceGeWithdrawableAmount() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            assertGe(
                flow.getBalance(streamId),
                flow.withdrawableAmountOf(streamId),
                "Invariant violation: withdrawable amount <= balance"
            );
        }
    }

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
