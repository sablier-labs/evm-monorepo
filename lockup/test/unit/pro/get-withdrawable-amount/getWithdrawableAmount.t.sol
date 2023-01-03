// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { E, SD1x18 } from "@prb/math/SD1x18.sol";
import { Solarray } from "solarray/Solarray.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Segment } from "src/types/Structs.sol";

import { ProTest } from "../ProTest.t.sol";

contract GetWithdrawableAmount__ProTest is ProTest {
    uint256 internal defaultStreamId;
    Segment[] internal maxSegments;

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(nonStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StartTimeGreaterThanCurrentTime() external StreamExistent {
        vm.warp({ timestamp: 0 });
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StartTimeEqualToCurrentTime() external StreamExistent {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier StartTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the deposit amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time > stop time
    /// - Current time = stop time
    function testGetWithdrawableAmount__CurrentTimeGreaterThanOrEqualToStopTime__NoWithdrawals(
        uint256 timeWarp
    ) external StreamExistent StartTimeLessThanCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_STOP_TIME + timeWarp });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time > stop time
    /// - Current time = stop time
    /// - Withdraw amount equal to deposit amount and not
    function testGetWithdrawableAmount__CurrentTimeGreaterThanOrEqualToStopTime__WithWithdrawals(
        uint256 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent StartTimeLessThanCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);
        withdrawAmount = boundUint128(withdrawAmount, 1, DEFAULT_NET_DEPOSIT_AMOUNT);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_STOP_TIME + timeWarp });

        // Withdraw the amount.
        pro.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CurrentTimeLessThanStopTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank(users.owner);
        comptroller.setProtocolFee(dai, ZERO);
        changePrank(users.sender);
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__WithWithdrawals(
        uint40 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent StartTimeLessThanCurrentTime CurrentTimeLessThanStopTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Bound the withdraw amount.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        uint128 initialWithdrawableAmount = calculateStreamedAmountForMultipleSegments(currentTime, DEFAULT_SEGMENTS);
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount);

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream with a custom gross deposit amount and operator fee.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );

        // Warp into the future.
        vm.warp({ timestamp: currentTime });

        // Make the withdrawal.
        pro.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = initialWithdrawableAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier NoWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__OneSegment(
        uint40 timeWarp
    ) external StreamExistent StartTimeLessThanCurrentTime CurrentTimeLessThanStopTime NoWithdrawals {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Create a single-element segment array.
        uint128 depositAmount = DEFAULT_SEGMENTS[0].amount + DEFAULT_SEGMENTS[1].amount;
        Segment[] memory segments = new Segment[](1);
        segments[0] = Segment({
            amount: depositAmount,
            exponent: DEFAULT_SEGMENTS[1].exponent,
            milestone: DEFAULT_STOP_TIME
        });

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream wit the one-segment arrays.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            depositAmount,
            segments,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForOneSegment(
            currentTime,
            depositAmount,
            segments[0].exponent
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier MultipleSegments() {
        unchecked {
            uint128 amount = DEFAULT_NET_DEPOSIT_AMOUNT / uint128(DEFAULT_MAX_SEGMENT_COUNT);
            SD1x18 exponent = E;
            uint40 duration = DEFAULT_TOTAL_DURATION / uint40(DEFAULT_MAX_SEGMENT_COUNT);

            // Generate a bunch of segments that each has the same amount, same exponent, and with milestones
            // evenly spread apart.
            for (uint40 i = 0; i < DEFAULT_MAX_SEGMENT_COUNT; i += 1) {
                maxSegments.push(
                    Segment({ amount: amount, exponent: exponent, milestone: DEFAULT_START_TIME + duration * (i + 1) })
                );
            }
        }
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentMilestone1st()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
        MultipleSegments
    {
        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream with the multiple-segment arrays.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            maxSegments,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForMultipleSegments(
            uint40(block.timestamp),
            maxSegments
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CurrentMilestoneNot1st() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentMilestoneNot1st(
        uint40 timeWarp
    ) external StreamExistent CurrentTimeLessThanStopTime NoWithdrawals MultipleSegments CurrentMilestoneNot1st {
        timeWarp = boundUint40(timeWarp, maxSegments[0].milestone, DEFAULT_TOTAL_DURATION - 1);

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream with the multiple-segment arrays.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            maxSegments,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForMultipleSegments(currentTime, maxSegments);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
