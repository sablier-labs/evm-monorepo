// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

contract StreamedAmountOf_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test {
    uint256 internal defaultStreamId;

    modifier whenStreamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    modifier whenStartTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < end time
    /// - Current time = end time
    /// - Current time > end time
    function testFuzz_StreamedAmountOf_OneSegment(uint40 timeWarp)
        external
        whenStreamActive
        whenStartTimeLessThanCurrentTime
    {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Create a single-element segment array.
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](1);
        segments[0] = LockupDynamic.Segment({
            amount: DEFAULT_DEPOSIT_AMOUNT,
            exponent: DEFAULT_SEGMENTS[1].exponent,
            milestone: DEFAULT_END_TIME
        });

        // Create the stream with the one-segment array.
        uint256 streamId = createDefaultStreamWithSegments(segments);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount =
            calculateStreamedAmountForOneSegment(currentTime, segments[0].exponent, DEFAULT_DEPOSIT_AMOUNT);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenMultipleSegments() {
        _;
    }

    modifier whenCurrentMilestoneNot1st() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < end time
    /// - Current time = end time
    /// - Current time > end time
    function testFuzz_StreamedAmountOf_CurrentMilestoneNot1st(uint40 timeWarp)
        external
        whenStreamActive
        whenStartTimeLessThanCurrentTime
        whenMultipleSegments
        whenCurrentMilestoneNot1st
    {
        timeWarp = boundUint40(timeWarp, MAX_SEGMENT_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Create the stream with the multiple-segment array.
        uint256 streamId = createDefaultStreamWithSegments(MAX_SEGMENTS);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount =
            calculateStreamedAmountForMultipleSegments(currentTime, MAX_SEGMENTS, DEFAULT_DEPOSIT_AMOUNT);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
