// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SCALE, SD59x18 } from "@prb/math/SD59x18.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__CreateWithDuration__DeltaCountOutOfBounds is SablierV2ProUnitTest {
    /// @dev it should revert.
    function testCannotCreateWithDuration() external {
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
}

contract DeltaCountWithinBounds {}

contract MilestonesCalculationOverflows {}

contract SablierV2Pro__CreateWithDuration__StartTimeGreaterThanCalculatedStopTime is
    SablierV2ProUnitTest,
    DeltaCountWithinBounds,
    MilestonesCalculationOverflows
{
    /// @dev it should revert.
    function testCannotCreateWithDuration() external {
        uint256 startTime = block.timestamp;
        uint256[] memory segmentDeltas = createDynamicArray(1, UINT256_MAX - startTime);
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
}

contract SablierV2Pro__CreateWithDuration__StartTimeGreaterThanCalculatedFirstMilestone is
    SablierV2ProUnitTest,
    DeltaCountWithinBounds,
    MilestonesCalculationOverflows
{
    /// @dev it should revert.
    function testCannotCreateWithDuration() external {
        uint256 startTime = block.timestamp;
        uint256[] memory segmentDeltas = createDynamicArray(UINT256_MAX, 1);
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
}

contract SablierV2Pro__CreateWithDuration__SegmentMilestonesNotOrdered is
    SablierV2ProUnitTest,
    DeltaCountWithinBounds,
    MilestonesCalculationOverflows
{
    /// @dev it should revert.
    function testCannotCreateWithDuration() external {
        uint256 startTime = block.timestamp;
        uint256[] memory segmentAmounts = createDynamicArray(0, SEGMENT_AMOUNTS_DAI[0], SEGMENT_AMOUNTS_DAI[1]);
        SD59x18[] memory segmentExponents = createDynamicArray(SCALE, SEGMENT_EXPONENTS[0], SEGMENT_EXPONENTS[1]);
        uint256[] memory segmentDeltas = createDynamicArray(1, UINT256_MAX, 1);
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
}

contract MilestonesCalculationDoesNotOverflow {}

contract SablierV2Pro__CreateWithDuration is
    SablierV2ProUnitTest,
    DeltaCountWithinBounds,
    MilestonesCalculationDoesNotOverflow
{
    /// @dev it should create the stream with duration.
    function testCreateWithDuration() external {
        uint256 daiStreamId = sablierV2Pro.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            SEGMENT_DELTAS,
            daiStream.cancelable
        );
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        ISablierV2Pro.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }
}
