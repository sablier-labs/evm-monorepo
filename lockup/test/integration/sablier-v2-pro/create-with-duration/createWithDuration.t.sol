// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract CreateWithDuration__Test is SablierV2ProTest {
    /// @dev it should revert.
    function testCannotCreateWithDuration__LoopCalculationOverflowsBlockGasLimit() external {
        uint64[] memory segmentDeltas = new uint64[](1_000_000);
        vm.expectRevert();
        sablierV2Pro.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            segmentDeltas,
            daiStream.cancelable
        );
    }

    modifier LoopCalculationDoesNotOverflowBlockGasLimit() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithDuration__SegmentDeltaCountNotEqual()
        external
        LoopCalculationDoesNotOverflowBlockGasLimit
    {
        uint256 deltaCount = daiStream.segmentAmounts.length + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentCountsNotEqual.selector,
                daiStream.segmentAmounts.length,
                daiStream.segmentExponents.length,
                deltaCount
            )
        );
        uint64[] memory segmentDeltas = new uint64[](deltaCount);
        for (uint64 i = 0; i < deltaCount; ) {
            segmentDeltas[i] = i;
            unchecked {
                i += 1;
            }
        }
        sablierV2Pro.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            segmentDeltas,
            daiStream.cancelable
        );
    }

    modifier SegmentDeltaEqual() {
        _;
    }

    modifier MilestonesCalculationOverflows() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithDuration__StartTimeGreaterThanCalculatedFirstMilestone()
        external
        LoopCalculationDoesNotOverflowBlockGasLimit
        SegmentDeltaEqual
        MilestonesCalculationOverflows
    {
        uint64 startTime = uint64(block.timestamp);
        uint64[] memory segmentDeltas = createDynamicUint64Array(UINT64_MAX, 1);
        uint64[] memory segmentMilestones = new uint64[](2);
        unchecked {
            segmentMilestones[0] = startTime + segmentDeltas[0];
            segmentMilestones[1] = segmentMilestones[0] + segmentDeltas[1];
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__StartTimeGreaterThanFirstMilestone.selector,
                startTime,
                segmentMilestones[0]
            )
        );
        sablierV2Pro.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            segmentDeltas,
            daiStream.cancelable
        );
    }

    /// @dev it should revert.
    function testCannotCreateWithDuration__SegmentMilestonesNotOrdered()
        external
        LoopCalculationDoesNotOverflowBlockGasLimit
        SegmentDeltaEqual
        MilestonesCalculationOverflows
    {
        uint64 startTime = uint64(block.timestamp);
        uint256[] memory segmentAmounts = createDynamicArray(0, SEGMENT_AMOUNTS_DAI[0], SEGMENT_AMOUNTS_DAI[1]);
        SD59x18[] memory segmentExponents = createDynamicArray(sd(1e18), SEGMENT_EXPONENTS[0], SEGMENT_EXPONENTS[1]);
        uint64[] memory segmentDeltas = createDynamicUint64Array(uint64(1), UINT64_MAX, 1);
        uint64[] memory segmentMilestones = new uint64[](3);
        unchecked {
            segmentMilestones[0] = startTime + segmentDeltas[0];
            segmentMilestones[1] = segmentMilestones[0] + segmentDeltas[1];
            segmentMilestones[2] = segmentMilestones[1] + segmentDeltas[2];
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                1,
                segmentMilestones[0],
                segmentMilestones[1]
            )
        );
        sablierV2Pro.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            segmentAmounts,
            segmentExponents,
            segmentDeltas,
            daiStream.cancelable
        );
    }

    modifier MilestonesCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should create the stream with duration.
    function testCreateWithDuration()
        external
        LoopCalculationDoesNotOverflowBlockGasLimit
        SegmentDeltaEqual
        MilestonesCalculationDoesNotOverflow
    {
        uint256 daiStreamId = sablierV2Pro.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            SEGMENT_DELTAS,
            daiStream.cancelable
        );
        DataTypes.ProStream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        DataTypes.ProStream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }
}
