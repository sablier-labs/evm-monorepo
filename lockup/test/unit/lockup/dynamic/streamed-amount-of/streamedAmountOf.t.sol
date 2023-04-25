// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";
import { StreamedAmountOf_Unit_Test } from "../../shared/streamed-amount-of/streamedAmountOf.t.sol";

contract StreamedAmountOf_Dynamic_Unit_Test is Dynamic_Unit_Test, StreamedAmountOf_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, StreamedAmountOf_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        StreamedAmountOf_Unit_Test.setUp();
    }

    modifier whenStatusStreaming() {
        _;
    }

    function test_StreamedAmountOf_StartTimeInTheFuture()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        vm.warp({ timestamp: 0 });
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_StreamedAmountOf_StartTimeInThePresent()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    function test_StreamedAmountOf_OneSegment()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
        whenStartTimeInThePast
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + 2000 seconds });

        // Create an array with one segment.
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](1);
        segments[0] = LockupDynamic.Segment({
            amount: DEFAULT_DEPOSIT_AMOUNT,
            exponent: DEFAULT_SEGMENTS[1].exponent,
            milestone: DEFAULT_END_TIME
        });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithSegments(segments);

        // Run the test.
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = 4472.13595499957941e18; // (0.2^0.5)*10,000
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenMultipleSegments() {
        _;
    }

    function test_StreamedAmountOf_CurrentMilestone1st()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
        whenMultipleSegments
        whenStartTimeInThePast
    {
        // Warp 1 second into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + 1 seconds });

        // Run the test.
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0.000000053506725e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenCurrentMilestoneNot1st() {
        _;
    }

    function test_StreamedAmountOf_CurrentMilestoneNot1st()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
        whenStartTimeInThePast
        whenMultipleSegments
        whenCurrentMilestoneNot1st
    {
        // Warp into the future. 750 seconds is ~10% of the way in the second segment.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 750 seconds });

        // Run the test.
        uint128 actualStreamedAmount = dynamic.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = DEFAULT_SEGMENTS[0].amount + 2371.708245126284505e18; // ~7,500*0.1^{0.5}
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
