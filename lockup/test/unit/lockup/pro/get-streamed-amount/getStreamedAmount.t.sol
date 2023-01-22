// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ZERO } from "@prb/math/UD60x18.sol";

import { Segment } from "src/types/Structs.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract GetStreamedAmount_Pro_Unit_Test is Pro_Unit_Test {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function test_GetStreamedAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint128 actualStreamedAmount = pro.getStreamedAmount(nullStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_GetStreamedAmount_StartTimeGreaterThanCurrentTime() external streamNonNull {
        vm.warp({ timestamp: 0 });
        uint128 actualStreamedAmount = pro.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return zero.
    function test_GetStreamedAmount_StartTimeEqualToCurrentTime() external streamNonNull {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualStreamedAmount = pro.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier startTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_GetStreamedAmount_OneSegment() external streamNonNull startTimeLessThanCurrentTime {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + 2_000 seconds });

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
        uint128 expectedStreamedAmount = 4472.13595499957941e18; // (0.2^0.5)*10,000
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier multipleSegments() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_GetStreamedAmount_CurrentMilestone1st()
        external
        streamNonNull
        multipleSegments
        startTimeLessThanCurrentTime
    {
        // Run the test.
        uint128 actualStreamedAmount = pro.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier currentMilestoneNot1st() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_GetStreamedAmount_CurrentMilestoneNot1st()
        external
        streamNonNull
        startTimeLessThanCurrentTime
        multipleSegments
        currentMilestoneNot1st
    {
        // Warp into the future. 750 seconds is ~10% of the way in the second segment.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 750 seconds });

        // Run the test.
        uint128 actualStreamedAmount = pro.getStreamedAmount(defaultStreamId);
        uint128 expectedStreamedAmount = DEFAULT_SEGMENTS[0].amount + 2371.708245126284505e18; // ~7,500*0.1^{0.5}
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
