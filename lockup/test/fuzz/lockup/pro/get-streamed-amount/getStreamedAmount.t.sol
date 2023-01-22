// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Broker, Segment } from "src/types/Structs.sol";

import { Pro_Fuzz_Test } from "../Pro.t.sol";

contract GetStreamedAmount_Pro_Fuzz_Test is Pro_Fuzz_Test {
    uint256 internal defaultStreamId;

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    modifier startTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < stop time
    /// - Current time = stop time
    /// - Current time > stop time
    function testFuzz_GetStreamedAmount_OneSegment(
        uint40 timeWarp
    ) external streamNonNull startTimeLessThanCurrentTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Create a single-element segment array.
        Segment[] memory segments = new Segment[](1);
        segments[0] = Segment({
            amount: DEFAULT_NET_DEPOSIT_AMOUNT,
            exponent: DEFAULT_SEGMENTS[1].exponent,
            milestone: DEFAULT_STOP_TIME
        });

        // Create the stream with the one-segment array.
        uint256 streamId = createDefaultStreamWithSegments(segments);

        // Run the test.
        uint128 actualStreamedAmount = pro.getStreamedAmount(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountForOneSegment(
            currentTime,
            segments[0].exponent,
            DEFAULT_NET_DEPOSIT_AMOUNT
        );
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier multipleSegments() {
        _;
    }

    modifier currentMilestoneNot1st() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < stop time
    /// - Current time = stop time
    /// - Current time > stop time
    function testFuzz_GetStreamedAmount_CurrentMilestoneNot1st(
        uint40 timeWarp
    ) external streamNonNull startTimeLessThanCurrentTime multipleSegments currentMilestoneNot1st {
        timeWarp = boundUint40(timeWarp, MAX_SEGMENTS[0].milestone, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Create the stream with the multiple-segment array.
        uint256 streamId = createDefaultStreamWithSegments(MAX_SEGMENTS);

        // Run the test.
        uint128 actualStreamedAmount = pro.getStreamedAmount(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountForMultipleSegments(
            currentTime,
            MAX_SEGMENTS,
            DEFAULT_NET_DEPOSIT_AMOUNT
        );
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
