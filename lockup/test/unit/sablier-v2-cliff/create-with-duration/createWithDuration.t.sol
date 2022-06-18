// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { stdError } from "forge-std/Test.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__CreateWithDuration is SablierV2CliffUnitTest {
    /// @dev When the cliff duration calculation overflows uint256, it should revert due to
    /// the start time being greater than the stop time
    function testCannotCreateWithDuration__CliffDurationCalculationOverflow(uint256 cliffDuration) external {
        vm.assume(cliffDuration > MAX_UINT_256 - block.timestamp);
        uint256 totalDuration = cliffDuration;
        uint256 cliffTime;
        uint256 stopTime;
        unchecked {
            cliffTime = block.timestamp + cliffDuration;
            stopTime = cliffTime;
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector,
                block.timestamp,
                stopTime
            )
        );
        sablierV2Cliff.createWithDuration(
            stream.sender,
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            cliffDuration,
            totalDuration,
            stream.cancelable
        );
    }

    /// @dev When the total duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__TotalDurationCalculationOverflow(
        uint256 cliffDuration,
        uint256 totalDuration
    ) external {
        vm.assume(cliffDuration <= MAX_UINT_256 - block.timestamp);
        vm.assume(totalDuration > MAX_UINT_256 - block.timestamp);
        uint256 stopTime;
        unchecked {
            stopTime = block.timestamp + totalDuration;
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector,
                block.timestamp,
                stopTime
            )
        );
        sablierV2Cliff.createWithDuration(
            stream.sender,
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            cliffDuration,
            totalDuration,
            stream.cancelable
        );
    }

    /// @dev When all checks pass, it should create the stream with duration.
    function testCreateWithDuration(uint256 cliffDuration, uint256 totalDuration) external {
        vm.assume(cliffDuration <= totalDuration);
        vm.assume(totalDuration <= MAX_UINT_256 - block.timestamp);
        uint256 cliffTime;
        uint256 stopTime;
        unchecked {
            cliffTime = block.timestamp + cliffDuration;
            stopTime = block.timestamp + totalDuration;
        }
        uint256 streamId = sablierV2Cliff.createWithDuration(
            stream.sender,
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            cliffDuration,
            totalDuration,
            stream.cancelable
        );
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(stream.token, createdStream.token);
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(cliffTime, createdStream.cliffTime);
        assertEq(stopTime, createdStream.stopTime);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }
}
