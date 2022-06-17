// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__CreateWithDuration is SablierV2LinearUnitTest {
    /// @dev When the total duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__TotalDurationCalculationOverflow(uint256 totalDuration) external {
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
        sablierV2Linear.createWithDuration(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            totalDuration,
            stream.cancelable
        );
    }

    /// @dev When all checks pass, it should create the stream with duration.
    function testCreateWithDuration(uint256 totalDuration) external {
        vm.assume(totalDuration <= MAX_UINT_256 - block.timestamp);
        uint256 streamId = sablierV2Linear.createWithDuration(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            totalDuration,
            stream.cancelable
        );
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        uint256 expectedStartTime = block.timestamp;
        uint256 expectedStopTime;
        unchecked {
            expectedStopTime = block.timestamp + totalDuration;
        }
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(stream.token, createdStream.token);
        assertEq(expectedStartTime, createdStream.startTime);
        assertEq(expectedStopTime, createdStream.stopTime);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }
}
