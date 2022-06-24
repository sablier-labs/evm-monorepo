// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SCALE, SD59x18 } from "@prb/math/SD59x18.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__UnitTest__CreateWithDuration is SablierV2ProUnitTest {
    /// @dev When the delta count is out of bounds, it should revert.
    function testCannotCreateWithDuration__DeltaCountOutOfBounds() external {
        uint256 deltaCount = sablierV2Pro.MAX_SEGMENT_COUNT() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentCountOutOfBounds.selector, deltaCount)
        );
        uint256[] memory segmentDeltas = new uint256[](deltaCount);
        for (uint256 i = 0; i < deltaCount; ) {
            segmentDeltas[i] = i;
            unchecked {
                i += 1;
            }
        }
        sablierV2Pro.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            segmentDeltas,
            daiStream.cancelable
        );
    }

    /// @dev When the milestone calculations overflow uint256 and the start time is greater than the calculated
    /// stop time, it should revert.
    function testCannotCreateWithDuration__MilestonesCalculationOverflow__StartTimeGreaterThanCalculatedStopTime()
        external
    {
        uint256 startTime = block.timestamp;
        uint256[] memory segmentDeltas = createDynamicArray(1, MAX_UINT_256 - startTime);
        uint256 stopTime = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector,
                daiStream.startTime,
                stopTime
            )
        );
        sablierV2Pro.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            segmentDeltas,
            daiStream.cancelable
        );
    }

    /// @dev When the milestone calculations overflow uint256 and the start time is greater than the calculated first
    /// milestone, it should revert.
    function testCannotCreateWithDuration__MilestonesCalculationOverflow__StartTimeGreaterThanCalculatedFirstMilestone()
        external
    {
        uint256 startTime = block.timestamp;
        uint256[] memory segmentDeltas = createDynamicArray(MAX_UINT_256, 1);
        uint256[] memory segmentMilestones = new uint256[](2);
        unchecked {
            segmentMilestones[0] = startTime + segmentDeltas[0];
            segmentMilestones[1] = segmentMilestones[0] + segmentDeltas[1];
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__StartTimeGreaterThanFirstMilestone.selector,
                startTime,
                segmentMilestones[0]
            )
        );
        sablierV2Pro.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            segmentDeltas,
            daiStream.cancelable
        );
    }

    /// @dev When the milestone calculations overflow uint256 and the segment milestones are not ordered,
    /// it should revert.
    function testCannotCreateWithDuration__MilestonesCalculationOverflow__SegmentMilestonesNotOrdered() external {
        uint256 startTime = block.timestamp;
        uint256[] memory segmentAmounts = createDynamicArray(0, SEGMENT_AMOUNTS_DAI[0], SEGMENT_AMOUNTS_DAI[1]);
        SD59x18[] memory segmentExponents = createDynamicArray(SCALE, SEGMENT_EXPONENTS[0], SEGMENT_EXPONENTS[1]);
        uint256[] memory segmentDeltas = createDynamicArray(1, MAX_UINT_256, 1);
        uint256[] memory segmentMilestones = new uint256[](3);
        unchecked {
            segmentMilestones[0] = startTime + segmentDeltas[0];
            segmentMilestones[1] = segmentMilestones[0] + segmentDeltas[1];
            segmentMilestones[2] = segmentMilestones[1] + segmentDeltas[2];
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                1,
                segmentMilestones[0],
                segmentMilestones[1]
            )
        );
        sablierV2Pro.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            segmentAmounts,
            segmentExponents,
            segmentDeltas,
            daiStream.cancelable
        );
    }

    /// @dev When all checks pass, it should create the stream with duration.
    function testCreateWithDuration() external {
        uint256 streamId = sablierV2Pro.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            SEGMENT_DELTAS,
            daiStream.cancelable
        );
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(streamId);
        ISablierV2Pro.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }
}
