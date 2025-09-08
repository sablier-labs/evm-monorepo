// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/types/Lockup.sol";
import { LockupDynamic } from "src/types/LockupDynamic.sol";

import { Lockup_Dynamic_Integration_Fuzz_Test } from "./LockupDynamic.t.sol";

contract StreamedAmountOf_Lockup_Dynamic_Integration_Fuzz_Test is Lockup_Dynamic_Integration_Fuzz_Test {
    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Status streaming
    /// - Status settled
    function testFuzz_StreamedAmountOf_OneSegment(
        LockupDynamic.Segment memory segment,
        uint40 timeJump
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenStartTimeInPast
    {
        vm.assume(segment.amount != 0);
        segment.timestamp = boundUint40(segment.timestamp, defaults.WARP_26_PERCENT(), defaults.END_TIME());
        timeJump = boundUint40(timeJump, defaults.WARP_26_PERCENT_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Create the single-segment array.
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](1);
        segments[0] = segment;

        // Mint enough tokens to the Sender.
        deal({ token: address(dai), to: users.sender, give: segment.amount });

        // Create the stream with the fuzzed segment.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();
        params.depositAmount = segment.amount;
        params.timestamps.end = segment.timestamp;
        uint256 streamId = lockup.createWithTimestampsLD(params, segments);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Run the test.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount =
            calculateStreamedAmountLD(segments, defaults.START_TIME(), params.depositAmount);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple deposit amounts
    /// - Status streaming
    /// - Status settled
    function testFuzz_StreamedAmountOf_Calculation(
        LockupDynamic.Segment[] memory segments,
        uint40 timeJump
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenStartTimeInPast
        givenMultipleSegments
        whenCurrentTimestampNot1st
    {
        vm.assume(segments.length > 1);

        // Fuzz the segment timestamps.
        fuzzSegmentTimestamps(segments, defaults.START_TIME());

        // Fuzz the segment amounts.
        uint128 depositAmount = fuzzDynamicStreamAmounts({ upperBound: MAX_UINT128, segments: segments });

        // Bound the time jump.
        uint40 firstSegmentDuration = segments[1].timestamp - segments[0].timestamp;
        uint40 totalDuration = segments[segments.length - 1].timestamp - defaults.START_TIME();
        timeJump = boundUint40(timeJump, firstSegmentDuration, totalDuration + 100 seconds);

        // Mint enough tokens to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream with the fuzzed segments.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();
        params.depositAmount = depositAmount;
        params.timestamps.end = segments[segments.length - 1].timestamp;
        uint256 streamId = lockup.createWithTimestampsLD(params, segments);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Run the test.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountLD(segments, defaults.START_TIME(), depositAmount);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev The streamed amount must never go down over time.
    function testFuzz_StreamedAmountOf_Monotonicity(
        LockupDynamic.Segment[] memory segments,
        uint40 timeWarp0,
        uint40 timeWarp1
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenStartTimeInPast
        givenMultipleSegments
        whenCurrentTimestampNot1st
    {
        vm.assume(segments.length > 1);

        // Fuzz the segment timestamps.
        fuzzSegmentTimestamps(segments, defaults.START_TIME());

        // Fuzz the segment amounts.
        uint128 depositAmount = fuzzDynamicStreamAmounts({ upperBound: MAX_UINT128, segments: segments });

        // Bound the time warps.
        uint40 firstSegmentDuration = segments[1].timestamp - segments[0].timestamp;
        uint40 totalDuration = segments[segments.length - 1].timestamp - defaults.START_TIME();
        timeWarp0 = boundUint40(timeWarp0, firstSegmentDuration, totalDuration - 1);
        timeWarp1 = boundUint40(timeWarp1, timeWarp0, totalDuration);

        // Mint enough tokens to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream with the fuzzed segments.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();
        params.depositAmount = depositAmount;
        params.timestamps.end = segments[segments.length - 1].timestamp;
        uint256 streamId = lockup.createWithTimestampsLD(params, segments);

        // Warp to the future for the first time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeWarp0 });

        // Calculate the streamed amount at this midpoint in time.
        uint128 streamedAmount0 = lockup.streamedAmountOf(streamId);

        // Warp to the future for the second time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeWarp1 });

        // Assert that this streamed amount is greater than or equal to the previous streamed amount.
        uint128 streamedAmount1 = lockup.streamedAmountOf(streamId);
        assertGe(streamedAmount1, streamedAmount0, "streamedAmount");
    }
}
