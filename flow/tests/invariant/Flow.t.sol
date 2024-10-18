// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Flow } from "src/types/DataTypes.sol";

import { Base_Test } from "./../Base.t.sol";
import { FlowAdminHandler } from "./handlers/FlowAdminHandler.sol";
import { FlowCreateHandler } from "./handlers/FlowCreateHandler.sol";
import { FlowHandler } from "./handlers/FlowHandler.sol";
import { FlowStore } from "./stores/FlowStore.sol";

/// @notice Common invariant test logic needed across contracts that inherit from {SablierFlow}.
contract Flow_Invariant_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20[] internal tokens;
    FlowAdminHandler internal flowAdminHandler;
    FlowCreateHandler internal flowCreateHandler;
    FlowHandler internal flowHandler;
    FlowStore internal flowStore;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Declare the default tokens.
        tokens.push(tokenWithoutDecimals);
        tokens.push(tokenWithProtocolFee);
        tokens.push(dai);
        tokens.push(usdc);
        tokens.push(IERC20(address(usdt)));

        // Deploy and the FlowStore contract.
        flowStore = new FlowStore(tokens);

        // Deploy the handlers.
        flowAdminHandler = new FlowAdminHandler({ flowStore_: flowStore, flow_: flow });
        flowCreateHandler = new FlowCreateHandler({ flowStore_: flowStore, flow_: flow });
        flowHandler = new FlowHandler({ flowStore_: flowStore, flow_: flow });

        // Label the contracts.
        vm.label({ account: address(flowAdminHandler), newLabel: "flowAdminHandler" });
        vm.label({ account: address(flowHandler), newLabel: "flowHandler" });
        vm.label({ account: address(flowCreateHandler), newLabel: "flowCreateHandler" });
        vm.label({ account: address(flowStore), newLabel: "flowStore" });

        // Target the flow handlers for invariant testing.
        targetContract(address(flowAdminHandler));
        targetContract(address(flowCreateHandler));
        targetContract(address(flowHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(flow));
        excludeSender(address(flowAdminHandler));
        excludeSender(address(flowCreateHandler));
        excludeSender(address(flowHandler));
        excludeSender(address(flowStore));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev For any stream, `snapshotTime` should never exceed the current block timestamp.
    function invariant_BlockTimestampGeSnapshotTime() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            assertGe(
                getBlockTimestamp(),
                flow.getSnapshotTime(streamId),
                "Invariant violation: block timestamp < snapshot time"
            );
        }
    }

    /// @dev For a given token,
    /// - the sum of all stream balances plus the protocol revenue should equal the aggregate balance.
    /// - token balance of the flow contract should be greater or equal to the sum of all stream balances and
    /// protocol revenue accrued for that token.
    /// - sum of all stream balances should equal to the sum of all deposited amounts minus the sum of all refunded and
    /// sum of all withdrawn.
    function invariant_ContractBalanceStreamBalancesProtocolRevenue() external view {
        // Check the invariant for each token.
        for (uint256 i = 0; i < tokens.length; ++i) {
            contractBalanceStreamBalancesProtocolRevenue(tokens[i]);
        }
    }

    function contractBalanceStreamBalancesProtocolRevenue(IERC20 token) internal view {
        uint256 contractBalance = token.balanceOf(address(flow));
        uint256 streamBalancesSum;

        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            if (flow.getToken(streamId) == token) {
                streamBalancesSum += flow.getBalance(streamId);
            }
        }

        assertEq(
            streamBalancesSum + flow.protocolRevenue(token),
            flow.aggregateBalance(token),
            unicode"Invariant violation: balance sum + revenue sum == aggregate balance"
        );

        assertGe(
            contractBalance,
            streamBalancesSum + flow.protocolRevenue(token),
            unicode"Invariant violation: contract balance >= Σ stream balances + protocol revenue"
        );

        assertEq(
            streamBalancesSum,
            flowStore.depositedAmountsSum(token) - flowStore.refundedAmountsSum(token)
                - flowStore.withdrawnAmountsSum(token),
            "Invariant violation: streamBalancesSum == depositedAmountsSum - refundedAmountsSum - withdrawnAmountsSum"
        );
    }

    /// @dev For a given token, token balance of the flow contract should be greater than or equal to the stored value
    /// of aggregate balance.
    function invariant_ContractBalanceGeAggregateBalance() external view {
        for (uint256 i = 0; i < tokens.length; ++i) {
            assertGe(
                tokens[i].balanceOf(address(flow)),
                flow.aggregateBalance(tokens[i]),
                unicode"Invariant violation: contract balance >= aggregate balance"
            );
        }
    }

    /// @dev For any stream, the snapshot time should be greater than or equal to the previous snapshot time.
    function invariant_SnapshotTimeAlwaysIncreases() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            assertGe(
                flow.getSnapshotTime(streamId),
                flowStore.previousSnapshotTime(streamId),
                "Invariant violation: snapshot time should never decrease"
            );
        }
    }

    /// @dev For any stream, if uncovered debt > 0, then the covered debt should equal the stream balance.
    function invariant_UncoveredDebt_CoveredDebtEqBalance() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.uncoveredDebtOf(streamId) > 0) {
                assertEq(
                    flow.coveredDebtOf(streamId),
                    flow.getBalance(streamId),
                    "Invariant violation: covered debt == balance"
                );
            }
        }
    }

    /// @dev If rps > 0, and no additional deposits are made, then the uncovered debt should never decrease.
    function invariant_RpsGt0_UncoveredDebtGt0_UncoveredDebtIncrease() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.getRatePerSecond(streamId).unwrap() > 0 && flowHandler.calls(streamId, "deposit") == 0) {
                assertGe(
                    flow.uncoveredDebtOf(streamId),
                    flowStore.previousUncoveredDebtOf(streamId),
                    "Invariant violation: uncovered debt should never decrease"
                );
            }
        }
    }

    /// @dev If rps > 0, no withdraw is made, the total debt should always increase.
    function invariant_RpsGt0_TotalDebtAlwaysIncreases() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.getRatePerSecond(streamId).unwrap() != 0 && flowHandler.calls(streamId, "withdraw") == 0) {
                assertGe(
                    flow.totalDebtOf(streamId),
                    flowStore.previousTotalDebtOf(streamId),
                    "Invariant violation: total debt should be monotonically increasing"
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
                "Invariant violation: deposited amount >= refunded amount + withdrawn amount"
            );
        }
    }

    /// @dev The sum of all deposited amounts should always be greater than or equal to the sum of withdrawn and
    /// refunded amounts.
    function invariant_InflowsSumGeOutflowsSum() external view {
        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 depositedAmountsSum = flowStore.depositedAmountsSum(tokens[i]);
            uint256 refundedAmountsSum = flowStore.refundedAmountsSum(tokens[i]);
            uint256 withdrawnAmountsSum = flowStore.withdrawnAmountsSum(tokens[i]);

            assertGe(
                depositedAmountsSum,
                refundedAmountsSum + withdrawnAmountsSum,
                "Invariant violation: deposited amounts sum >= refunded amounts sum + withdrawn amounts sum"
            );
        }
    }

    /// @dev The next stream ID should always be incremented by 1.
    function invariant_NextStreamId() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 nextStreamId = flow.nextStreamId();
            assertEq(nextStreamId, lastStreamId + 1, "Invariant violation: next stream ID not incremented");
        }
    }

    /// @dev If there is no uncovered debt, the covered debt should always be equal to
    /// the total debt.
    function invariant_NoUncoveredDebt_StreamedPaused_CoveredDebtEqTotalDebt() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.uncoveredDebtOf(streamId) == 0) {
                assertEq(
                    flow.coveredDebtOf(streamId),
                    flow.totalDebtOf(streamId),
                    "Invariant violation: paused stream covered debt == snapshot debt"
                );
            }
        }
    }

    /// @dev The stream balance should be equal to the sum of the covered debt and the refundable amount.
    function invariant_StreamBalanceEqCoveredDebtPlusRefundableAmount() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            assertEq(
                flow.getBalance(streamId),
                flow.coveredDebtOf(streamId) + flow.refundableAmountOf(streamId),
                "Invariant violation: stream balance == covered debt + refundable amount"
            );
        }
    }

    /// @dev For non-voided streams, if the rate per second is non-zero, then it must imply that the status must be
    /// either `STREAMING_SOLVENT` or `STREAMING_INSOLVENT`.
    function invariant_RatePerSecondNotZero_Streaming_Status() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (!flow.isVoided(streamId) && flow.getRatePerSecond(streamId).unwrap() > 0) {
                assertTrue(
                    flow.isPaused(streamId) == false, "Invariant violation: rate per second not zero but stream paused"
                );
                assertTrue(
                    flow.statusOf(streamId) == Flow.Status.STREAMING_SOLVENT
                        || flow.statusOf(streamId) == Flow.Status.STREAMING_INSOLVENT,
                    "Invariant violation: rate per second not zero but stream status not correct"
                );
            }
        }
    }

    /// @dev For non-voided streams, if the rate per second is zero, then it must imply that the stream is paused and
    /// the status must be either `PAUSED_SOLVENT` or `PAUSED_INSOLVENT`.
    function invariant_RatePerSecondZero_StreamPaused_Status() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (!flow.isVoided(streamId) && flow.getRatePerSecond(streamId).unwrap() == 0) {
                assertTrue(
                    flow.isPaused(streamId) == true, "Invariant violation: rate per second zero but stream not paused"
                );
                assertTrue(
                    flow.statusOf(streamId) == Flow.Status.PAUSED_SOLVENT
                        || flow.statusOf(streamId) == Flow.Status.PAUSED_INSOLVENT,
                    "Invariant violation: rate per second zero but stream status not correct"
                );
            }
        }
    }

    /// @dev If the stream is paused, then the rate per second should always be zero.
    function invariant_StreamPaused_RatePerSecondZero() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.isPaused(streamId)) {
                assertEq(
                    flow.getRatePerSecond(streamId).unwrap(),
                    0,
                    "Invariant violation: paused stream with a non-zero rate per second"
                );
            }
        }
    }

    /// @dev If the stream is voided, it should be paused, and uncovered debt should be zero.
    function invariant_StreamVoided_StreamPaused_RefundableAmountZero_UncoveredDebtZero() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);
            if (flow.isVoided(streamId)) {
                assertTrue(flow.isPaused(streamId), "Invariant violation: voided stream is not paused");
                assertEq(
                    flow.uncoveredDebtOf(streamId), 0, "Invariant violation: voided stream with non-zero uncovered debt"
                );
            }
        }
    }

    /// @dev For non-voided streams, the expected streamed amount should be greater than or equal to the sum of total
    /// debt and withdrawn amount. And, the difference between the two should not exceed 10 mvt.
    function invariant_TotalStreamedEqTotalDebtPlusWithdrawn() external view {
        uint256 lastStreamId = flowStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = flowStore.streamIds(i);

            // Skip the voided streams.
            if (!flow.isVoided(streamId)) {
                uint256 expectedTotalStreamed =
                    calculateExpectedStreamedAmount(flowStore.streamIds(i), flow.getTokenDecimals(streamId));
                uint256 actualTotalStreamed = flow.totalDebtOf(streamId) + flowStore.withdrawnAmounts(streamId);

                assertGe(
                    expectedTotalStreamed,
                    actualTotalStreamed,
                    "Invariant violation: expected streamed amount >= total debt + withdrawn amount"
                );

                assertLe(
                    expectedTotalStreamed - actualTotalStreamed,
                    10,
                    "Invariant violation: expected streamed amount - total debt + withdrawn amount <= 10"
                );
            }
        }
    }

    /// @dev Calculates the maximum possible amount streamed, denoted in token's decimal, by iterating over all the
    /// periods during which rate per second remained constant followed by descaling at the last step.
    function calculateExpectedStreamedAmount(
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

            // If end time is 0, consider current time as the end time.
            uint128 elapsed = period.end > 0 ? period.end - period.start : uint40(block.timestamp) - period.start;

            // Increment total streamed amount by the amount streamed during this period.
            expectedStreamedAmount += period.ratePerSecond * elapsed;
        }

        // Descale the total streamed amount to token's decimal to get the maximum possible amount streamed.
        return getDescaledAmount(expectedStreamedAmount, decimals);
    }
}
