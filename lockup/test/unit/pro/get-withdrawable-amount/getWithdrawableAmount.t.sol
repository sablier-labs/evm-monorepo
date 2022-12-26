// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { ProTest } from "../ProTest.t.sol";

contract GetWithdrawableAmount__Test is ProTest {
    uint256 internal defaultStreamId;
    SD1x18 internal constant E = SD1x18.wrap(2_718281828459045235);
    uint128[] internal maxSegmentAmounts = new uint128[](MAX_SEGMENT_COUNT);
    SD1x18[] internal maxSegmentExponents = new SD1x18[](MAX_SEGMENT_COUNT);
    uint40[] internal maxSegmentMilestones = new uint40[](MAX_SEGMENT_COUNT);

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
        vm.warp({ timestamp: defaultStream.startTime });
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
    /// - current time > stop time
    /// - current time = stop time
    function testGetWithdrawableAmount__CurrentTimeGreaterThanOrEqualToStopTime__NoWithdrawals(
        uint256 timeWarp
    ) external StreamExistent StartTimeLessThanCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.stopTime + timeWarp });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaultStream.depositAmount;
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
        withdrawAmount = boundUint128(withdrawAmount, 1, defaultStream.depositAmount);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.stopTime + timeWarp });

        // Withdraw the amount.
        pro.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaultStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CurrentTimeLessThanStopTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank(users.owner);
        comptroller.setProtocolFee(defaultStream.token, ZERO);
        changePrank(users.sender);
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__WithWithdrawals(
        uint40 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent StartTimeLessThanCurrentTime CurrentTimeLessThanStopTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Calculate the segment amounts.
        uint128[] memory segmentAmounts = calculateSegmentAmounts(defaultStream.depositAmount);

        // Bound the withdraw amount.
        uint40 currentTime = defaultStream.startTime + timeWarp;
        uint128 initialWithdrawableAmount = calculateStreamedAmountForMultipleSegments(
            currentTime,
            segmentAmounts,
            defaultStream.segmentExponents,
            defaultStream.segmentMilestones
        );
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount);

        // Mint tokens to the sender.
        deal({ token: defaultStream.token, to: defaultStream.sender, give: defaultStream.depositAmount });

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream with a custom gross deposit amount and operator fee.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultStream.depositAmount,
            segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
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

        // Create the one-segment arrays.
        uint128 depositAmount = DEFAULT_SEGMENT_AMOUNTS[0] + DEFAULT_SEGMENT_AMOUNTS[1];
        uint128[] memory segmentAmounts = createDynamicUint128Array(depositAmount);
        SD1x18[] memory segmentExponents = createDynamicArray(DEFAULT_SEGMENT_EXPONENTS[1]);
        uint40[] memory segmentMilestones = createDynamicUint40Array(DEFAULT_STOP_TIME);

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream wit the one-segment arrays.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            depositAmount,
            segmentAmounts,
            segmentExponents,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            segmentMilestones
        );

        // Warp into the future.
        uint40 currentTime = defaultStream.startTime + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForOneSegment(
            currentTime,
            depositAmount,
            segmentExponents[0]
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier MultipleSegments() {
        unchecked {
            uint128 segmentAmount = defaultStream.depositAmount / uint128(MAX_SEGMENT_COUNT);
            SD1x18 segmentExponent = E;
            uint40 segmentDuration = DEFAULT_TOTAL_DURATION / uint40(MAX_SEGMENT_COUNT);

            // Generate lots of segments that each have the same amount, same exponent, and with milestones
            // evenly spread apart.
            for (uint40 i = 0; i < MAX_SEGMENT_COUNT; i += 1) {
                maxSegmentAmounts[i] = segmentAmount;
                maxSegmentExponents[i] = segmentExponent;
                maxSegmentMilestones[i] = defaultStream.startTime + segmentDuration * (i + 1);
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
            defaultStream.depositAmount,
            maxSegmentAmounts,
            maxSegmentExponents,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            maxSegmentMilestones
        );

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForMultipleSegments(
            uint40(block.timestamp),
            maxSegmentAmounts,
            maxSegmentExponents,
            maxSegmentMilestones
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
        timeWarp = boundUint40(timeWarp, maxSegmentMilestones[0], DEFAULT_TOTAL_DURATION - 1);

        // Disable the operator fee so that it doesn't interfere with the calculations.
        UD60x18 operatorFee = ZERO;

        // Create the stream with the multiple-segment arrays.
        uint256 streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultStream.depositAmount,
            maxSegmentAmounts,
            maxSegmentExponents,
            defaultArgs.createWithMilestones.operator,
            operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            maxSegmentMilestones
        );

        // Warp into the future.
        uint40 currentTime = defaultStream.startTime + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForMultipleSegments(
            currentTime,
            maxSegmentAmounts,
            maxSegmentExponents,
            maxSegmentMilestones
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
