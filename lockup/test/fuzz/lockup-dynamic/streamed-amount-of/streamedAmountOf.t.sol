// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ZERO } from "@prb/math/UD60x18.sol";
import { Broker, LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

contract StreamedAmountOf_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test {
    function setUp() public virtual override {
        Dynamic_Fuzz_Test.setUp();

        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        changePrank({ msgSender: users.sender });
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Status streaming
    /// - Status settled
    function testFuzz_StreamedAmountOf_OneSegment(
        LockupDynamic.Segment memory segment,
        uint40 timeWarp
    )
        external
        whenStartTimeInThePast
    {
        vm.assume(segment.amount != 0);
        segment.milestone = boundUint40(segment.milestone, DEFAULT_CLIFF_TIME, DEFAULT_END_TIME);
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Create the single-segment array.
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](1);
        segments[0] = segment;

        // Mint enough assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: users.sender, give: segment.amount });

        // Create the stream with the fuzzed segment.
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = segment.amount;
        params.segments = segments;
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = dynamic.createWithMilestones(params);

        // Simulate the passage of time.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountForOneSegment(currentTime, segment);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenMultipleSegments() {
        _;
    }

    modifier whenCurrentMilestoneNot1st() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple deposit amounts
    /// - Status streaming
    /// - Status settled
    function testFuzz_StreamedAmountOf_Calculation(
        LockupDynamic.Segment[] memory segments,
        uint40 timeWarp
    )
        external
        whenStartTimeInThePast
        whenMultipleSegments
        whenCurrentMilestoneNot1st
    {
        vm.assume(segments.length > 1);

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(segments, DEFAULT_START_TIME);

        // Fuzz the segment amounts.
        (uint128 totalAmount,) = fuzzDynamicStreamAmounts({
            upperBound: UINT128_MAX,
            segments: segments,
            protocolFee: ZERO,
            brokerFee: ZERO
        });

        // Bound the time warp.
        uint40 firstSegmentDuration = segments[1].milestone - segments[0].milestone;
        uint40 totalDuration = segments[segments.length - 1].milestone - DEFAULT_START_TIME;
        timeWarp = boundUint40(timeWarp, firstSegmentDuration, totalDuration + 100 seconds);

        // Mint enough assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: users.sender, give: totalAmount });

        // Create the stream with the fuzzed segments.
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = totalAmount;
        params.segments = segments;
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = dynamic.createWithMilestones(params);

        // Simulate the passage of time.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountForMultipleSegments(currentTime, segments, totalAmount);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev The streamed amount must never go down over time.
    function testFuzz_StreamedAmountOf_Monotonicity(
        LockupDynamic.Segment[] memory segments,
        uint40 timeWarp0,
        uint40 timeWarp1
    )
        external
        whenStartTimeInThePast
        whenMultipleSegments
        whenCurrentMilestoneNot1st
    {
        vm.assume(segments.length > 1);

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(segments, DEFAULT_START_TIME);

        // Fuzz the segment amounts.
        (uint128 totalAmount,) = fuzzDynamicStreamAmounts({
            upperBound: UINT128_MAX,
            segments: segments,
            protocolFee: ZERO,
            brokerFee: ZERO
        });

        // Bound the time warps.
        uint40 firstSegmentDuration = segments[1].milestone - segments[0].milestone;
        uint40 totalDuration = segments[segments.length - 1].milestone - DEFAULT_START_TIME;
        timeWarp0 = boundUint40(timeWarp0, firstSegmentDuration, totalDuration - 1);
        timeWarp1 = boundUint40(timeWarp1, timeWarp0, totalDuration);

        // Mint enough assets to the sender.
        deal({ token: address(DEFAULT_ASSET), to: users.sender, give: totalAmount });

        // Create the stream with the fuzzed segments.
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = totalAmount;
        params.segments = segments;
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = dynamic.createWithMilestones(params);

        // Warp to the future for the first time.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp0 });

        // Calculate the streamed amount at this midpoint in time.
        uint128 streamedAmount0 = dynamic.streamedAmountOf(streamId);

        // Warp to the future for the second time.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp1 });

        // Assert that this streamed amount is greater than or equal to the previous streamed amount.
        uint128 streamedAmount1 = dynamic.streamedAmountOf(streamId);
        assertGte(streamedAmount1, streamedAmount0, "streamedAmount");
    }
}
