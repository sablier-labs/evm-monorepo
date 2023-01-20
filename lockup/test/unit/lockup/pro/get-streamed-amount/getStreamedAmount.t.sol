// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { E, UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Broker, Segment } from "src/types/Structs.sol";

import { Pro_Test } from "../Pro.t.sol";

contract GetStreamedAmount_Pro_Test is Pro_Test {
    uint256 internal defaultStreamId;
    Segment[] internal maxSegments;

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
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank(users.admin);
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        changePrank(users.sender);
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

        // Create a single-element segment array.
        Segment[] memory segments = new Segment[](1);
        segments[0] = Segment({
            amount: DEFAULT_NET_DEPOSIT_AMOUNT,
            exponent: DEFAULT_SEGMENTS[1].exponent,
            milestone: DEFAULT_STOP_TIME
        });

        // Create the stream wit the one-segment arrays. The broker fee is disabled so that it doesn't interfere
        // with the calculations.
        uint256 streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

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
        unchecked {
            uint128 amount = DEFAULT_NET_DEPOSIT_AMOUNT / uint128(DEFAULT_MAX_SEGMENT_COUNT);
            UD2x18 exponent = E;
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

    /// @dev it should return the correct streamed amount.
    function test_GetStreamedAmount_CurrentMilestone1st()
        external
        streamNonNull
        multipleSegments
        startTimeLessThanCurrentTime
    {
        // Create the stream with the multiple-segment arrays. The broker fee is disabled so that it doesn't interfere
        // with the calculations.
        uint256 streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            maxSegments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Run the test.
        uint128 actualStreamedAmount = pro.getStreamedAmount(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountForMultipleSegments(
            uint40(block.timestamp),
            maxSegments,
            DEFAULT_NET_DEPOSIT_AMOUNT
        );
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
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
        timeWarp = boundUint40(timeWarp, maxSegments[0].milestone, DEFAULT_TOTAL_DURATION * 2);

        // Create the stream with the multiple-segment arrays. The broker fee is disabled so that it doesn't interfere
        // with the calculations.
        uint256 streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            maxSegments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualStreamedAmount = pro.getStreamedAmount(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountForMultipleSegments(
            currentTime,
            maxSegments,
            DEFAULT_NET_DEPOSIT_AMOUNT
        );
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
