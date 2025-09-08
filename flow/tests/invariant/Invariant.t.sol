// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StdInvariant } from "forge-std/src/StdInvariant.sol";

import { Flow } from "src/types/DataTypes.sol";

import { Base_Test } from "./../Base.t.sol";
import { FlowComptrollerHandler } from "./handlers/FlowComptrollerHandler.sol";
import { FlowCreateHandler } from "./handlers/FlowCreateHandler.sol";
import { FlowHandler } from "./handlers/FlowHandler.sol";
import { FlowStore } from "./stores/FlowStore.sol";

/// @notice Invariants of {SablierFlow} contract.
contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    FlowComptrollerHandler internal flowComptrollerHandler;
    FlowCreateHandler internal flowCreateHandler;
    FlowHandler internal flowHandler;
    FlowStore internal flowStore;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy and the FlowStore contract.
        flowStore = new FlowStore(tokens);

        // Deploy the handlers.
        flowComptrollerHandler = new FlowComptrollerHandler({ flowStore_: flowStore, flow_: flow });
        flowCreateHandler = new FlowCreateHandler({ flowStore_: flowStore, flow_: flow });
        flowHandler = new FlowHandler({ flowStore_: flowStore, flow_: flow });

        // Label the contracts.
        vm.label({ account: address(flowComptrollerHandler), newLabel: "flowComptrollerHandler" });
        vm.label({ account: address(flowHandler), newLabel: "flowHandler" });
        vm.label({ account: address(flowCreateHandler), newLabel: "flowCreateHandler" });
        vm.label({ account: address(flowStore), newLabel: "flowStore" });

        // Target the flow handlers for invariant testing.
        targetContract(address(flowComptrollerHandler));
        targetContract(address(flowCreateHandler));
        targetContract(address(flowHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(flow));
        excludeSender(address(flowComptrollerHandler));
        excludeSender(address(flowCreateHandler));
        excludeSender(address(flowHandler));
        excludeSender(address(flowStore));
    }

    /*//////////////////////////////////////////////////////////////////////////
                              UNCONDITIONAL INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Balances invariants:
    /// - The ERC-20 balance of the Flow contract should always be greater than or equal to the aggregated amount.
    /// - The ERC-20 balance of the Flow contract should always be greater than or equal to the stream balances sum.
    /// - The stream balances sum should equal the aggregate amount.
    /// - The stream balances sum should should equal the total deposits minus the total refunds and total withdrawals.
    function invariant_Balances() external view {
        // Check the invariant for each token.
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = IERC20(tokens[i]);
            uint256 erc20Balance = token.balanceOf(address(flow));
            uint256 streamBalancesSum;

            uint256 lastStreamId = flowStore.lastStreamId();
            for (uint256 j = 0; j < lastStreamId; ++j) {
                uint256 streamId = flowStore.streamIds(j);

                if (flow.getToken(streamId) == token) {
                    streamBalancesSum += flow.getBalance(streamId);
                }
            }

            assertGe(
                erc20Balance,
                flow.aggregateAmount(token),
                unicode"Invariant violation: ERC-20 balance < aggregate amount"
            );

            assertGe(erc20Balance, streamBalancesSum, unicode"Invariant violation: ERC-20 balance < Σ stream balances");

            assertEq(
                streamBalancesSum,
                flow.aggregateAmount(token),
                unicode"Invariant violation: Σ stream balances != aggregate amount"
            );

            assertEq(
                streamBalancesSum,
                flowStore.totalDepositsByToken(token) - flowStore.totalRefundsByToken(token)
                    - flowStore.totalWithdrawalsByToken(token),
                unicode"Invariant violation: Σ stream balances != Σ deposits - Σ refunds - Σ withdrawals"
            );
        }
    }

    /// @dev The total deposits should always be greater than or equal to the total withdrawals and total refunds
    /// combined.
    function invariant_InflowGeOutflow_ByStream() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            assertGe(
                flowStore.totalDepositsByStream(streamId),
                flowStore.totalRefundsByStream(streamId) + flowStore.totalWithdrawalsByStream(streamId),
                unicode"Invariant violation: Σ deposits < Σ refunds + Σ withdrawals"
            );
        }
    }

    /// @dev The total deposits should always be greater than or equal to the total withdrawals and total refunds
    /// combined.
    function invariant_InflowsGeOutflows_ByToken() external view {
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = IERC20(tokens[i]);

            assertGe(
                flowStore.totalDepositsByToken(token),
                flowStore.totalRefundsByToken(token) + flowStore.totalWithdrawalsByToken(token),
                unicode"Invariant violation: Σ deposits < Σ refunds + Σ withdrawals"
            );
        }
    }

    /// @dev The next stream ID should always be incremented by 1.
    function invariant_NextStreamId() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        uint256 nextStreamId = flow.nextStreamId();
        assertEq(nextStreamId, lastStreamId + 1, "Invariant violation: next stream ID not incremented");
    }

    /// @dev The stream balance should always equal the sum of the covered debt and the refundable amount.
    function invariant_StreamBalanceEqCoveredDebtPlusRefundableAmount() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            assertEq(
                flow.getBalance(streamId),
                flow.coveredDebtOf(streamId) + flow.refundableAmountOf(streamId),
                "Invariant violation: stream balance != covered debt + refundable amount"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                               CONDITIONAL INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev If RPS > 0, the status should be be PENDING, STREAMING_SOLVENT or STREAMING_INSOLVENT.
    function invariant_RPSNotZero_StatusPendingOrStreaming() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            uint128 rps = flow.getRatePerSecond(streamId).unwrap();
            Flow.Status status = flow.statusOf(streamId);
            if (rps > 0) {
                assertTrue(
                    status == Flow.Status.PENDING || status == Flow.Status.STREAMING_SOLVENT
                        || status == Flow.Status.STREAMING_INSOLVENT,
                    "Invariant violation: RPS != 0 but stream status not pending or streaming"
                );
            }
        }
    }

    /// @dev If RPS > 0 and no withdrawals are made, the total debt should never decrease.
    function invariant_RPSNotZero_TotalDebtAlwaysIncreases() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            uint128 rps = flow.getRatePerSecond(streamId).unwrap();
            if (rps > 0 && flowHandler.calls(streamId, "withdraw") == 0) {
                assertGe(
                    flow.totalDebtOf(streamId),
                    flowStore.previousTotalDebtOf(streamId),
                    "Invariant violation: total debt decreased"
                );
            }
        }
    }

    /// @dev If RPS > 0 and no additional deposits are made, then the uncovered debt should never decrease.
    function invariant_RPSNotZero_AndUncoveredDebtGt0_UncoveredDebtAlwaysIncreases() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            uint128 rps = flow.getRatePerSecond(streamId).unwrap();
            if (rps > 0 && flowHandler.calls(streamId, "deposit") == 0) {
                assertGe(
                    flow.uncoveredDebtOf(streamId),
                    flowStore.previousUncoveredDebtOf(streamId),
                    "Invariant violation: uncovered debt decreased"
                );
            }
        }
    }

    /// @dev If RPS = 0 and non-voided stream, the status should be PAUSED.
    function invariant_RPSZero_NonVoided_StatusPaused() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            uint128 rps = flow.getRatePerSecond(streamId).unwrap();
            if (rps == 0 && !flow.isVoided(streamId)) {
                assertTrue(
                    flow.statusOf(streamId) == Flow.Status.PAUSED_SOLVENT
                        || flow.statusOf(streamId) == Flow.Status.PAUSED_INSOLVENT,
                    "Invariant violation: RPS = 0 but stream status not paused"
                );
            }
        }
    }

    /// @dev See diagram at https://docs.sablier.com/concepts/flow/statuses.
    function invariant_StatusTransitions() external view {
        uint256 lastStreamId = flowStore.lastStreamId();

        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            Flow.Status currentStatus = flow.statusOf(streamId);
            Flow.Status previousStatus = flowStore.previousStatusOf(streamId);

            // If the previous status is not PENDING, the current status should not be PENDING.
            if (previousStatus != Flow.Status.PENDING) {
                assertNotEq(currentStatus, Flow.Status.PENDING, "Invariant violation: not pending -> pending");
            }

            // If the previous status is PENDING, the current status should not be PAUSED.
            if (previousStatus == Flow.Status.PENDING) {
                assertNotEq(currentStatus, Flow.Status.PAUSED_SOLVENT, "Invariant violation: pending -> paused solvent");
                assertNotEq(
                    currentStatus, Flow.Status.PAUSED_INSOLVENT, "Invariant violation: pending -> paused insolvent"
                );
            }

            // If the previous status is PAUSED_SOLVENT, the current status should not be PAUSED_INSOLVENT.
            if (previousStatus == Flow.Status.PAUSED_SOLVENT) {
                assertNotEq(
                    currentStatus,
                    Flow.Status.PAUSED_INSOLVENT,
                    "Invariant violation: paused solvent -> paused insolvent"
                );
            }

            // If the previous status is VOIDED, the current status should also be VOIDED.
            if (previousStatus == Flow.Status.VOIDED) {
                assertEq(currentStatus, Flow.Status.VOIDED, "Invariant violation: voided -> not voided");
            }
        }
    }

    /// @dev For non-pending streams, the snapshot time should never exceed the current block timestamp.
    function invariant_StatusNonPending_BlockTimestampGeSnapshotTime() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            if (flow.statusOf(streamId) != Flow.Status.PENDING) {
                assertGe(
                    getBlockTimestamp(),
                    flow.getSnapshotTime(streamId),
                    "Invariant violation: pending stream with block timestamp < snapshot time"
                );
            }
        }
    }

    /// @dev For non-voided streams, the snapshot time should never decrease.
    function invariant_StatusNonVoided_SnapshotTimeAlwaysIncreases() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.statusOf(streamId) != Flow.Status.VOIDED) {
                assertGe(
                    flow.getSnapshotTime(streamId),
                    flowStore.previousSnapshotTime(streamId),
                    "Invariant violation: snapshot time decreased"
                );
            }
        }
    }

    /// @dev For non-voided streams, the expected total streamed amount should equal the sum of the total withdrawals
    /// and total debt.
    function invariant_StatusNonVoided_TotalStreamedEqTotalDebtPlusWithdrawn() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            if (!flow.isVoided(streamId)) {
                uint256 expectedTotalStreamed =
                    calculateExpectedTotalStreamed(flowStore.streamIds(i), flow.getTokenDecimals(streamId));
                uint256 actualTotalStreamed = flow.totalDebtOf(streamId) + flowStore.totalWithdrawalsByStream(streamId);

                assertEq(
                    expectedTotalStreamed,
                    actualTotalStreamed,
                    "Invariant violation: expected total streamed amount != total debt + withdrawn amount"
                );
            }
        }
    }

    /// @dev For pending streams, the RPS should be greater than zero and the total debt should be zero.
    function invariant_StatusPending_RPSGt0_TotalDebtEq0() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            if (flow.statusOf(streamId) == Flow.Status.PENDING) {
                assertGt(
                    flow.getSnapshotTime(streamId),
                    getBlockTimestamp(),
                    unicode"Invariant violation: pending stream with snapshot time ≤ block timestamp"
                );
                assertGt(
                    flow.getRatePerSecond(streamId).unwrap(), 0, "Invariant violation: pending stream with RPS = 0"
                );
                assertEq(flow.totalDebtOf(streamId), 0, "Invariant violation: pending stream with total debt > 0");
            }
        }
    }

    /// @dev For paused streams, the RPS should be zero.
    function invariant_StatusPaused_RPS0() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            Flow.Status status = flow.statusOf(streamId);
            if (status == Flow.Status.PAUSED_INSOLVENT || status == Flow.Status.PAUSED_SOLVENT) {
                assertEq(
                    flow.getRatePerSecond(streamId).unwrap(), 0, "Invariant violation: paused status with RPS != 0"
                );
            }
        }
    }

    /// @dev For voided streams, the uncovered debt should be zero.
    function invariant_StatusVoided_UncoveredDebtZero() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.isVoided(streamId)) {
                assertEq(
                    flow.uncoveredDebtOf(streamId), 0, "Invariant violation: voided stream with uncovered debt > 0"
                );
            }
        }
    }

    /// @dev If uncovered debt = 0, the covered debt should equal the total debt.
    function invariant_UncoveredDebt0_StreamedPaused_CoveredDebtEqTotalDebt() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.uncoveredDebtOf(streamId) == 0) {
                assertEq(
                    flow.coveredDebtOf(streamId),
                    flow.totalDebtOf(streamId),
                    "Invariant violation: paused stream covered debt != total debt"
                );
            }
        }
    }

    /// @dev If uncovered debt > 0, the covered debt should equal the stream balance.
    function invariant_UncoveredDebtGt0_CoveredDebtEqBalance() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.uncoveredDebtOf(streamId) > 0) {
                assertEq(
                    flow.coveredDebtOf(streamId),
                    flow.getBalance(streamId),
                    "Invariant violation: covered debt != balance"
                );
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the total amount streamed by iterating over all the periods during which RPS remained constant
    /// followed by descaling at the last step.
    function calculateExpectedTotalStreamed(
        uint256 streamId,
        uint8 decimals
    )
        internal
        view
        returns (uint256 expectedStreamedAmount)
    {
        uint256 count = flowStore.getPeriods(streamId).length;

        for (uint256 i = 0; i < count; ++i) {
            FlowStore.Period memory period = flowStore.getPeriod(streamId, i);

            // If the start time is greater than the current time, then accumulating debt has not started yet.
            if (period.start > getBlockTimestamp()) {
                return 0;
            }

            // If end time is 0, consider current time as the end time.
            uint128 elapsed = period.end > 0 ? period.end - period.start : getBlockTimestamp() - period.start;

            // Increment total streamed amount by the amount streamed during this period.
            expectedStreamedAmount += period.ratePerSecond * elapsed;
        }

        // Descale the total streamed amount to token's decimal to get the maximum possible amount streamed.
        return getDescaledAmount(expectedStreamedAmount, decimals);
    }
}
