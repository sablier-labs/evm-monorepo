// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__CreateWithDuration is SablierV2LinearUnitTest {
    /// @dev When the total duration calculation overflows uint256, it should revert due to
    /// the start time being greater than the stop time.
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
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            totalDuration,
            daiStream.cancelable
        );
    }

    /// @dev When all checks pass, it should create the stream with duration.
    function testCreateWithDuration(uint256 totalDuration) external {
        vm.assume(totalDuration <= MAX_UINT_256 - block.timestamp);
        uint256 streamId = sablierV2Linear.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            totalDuration,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(streamId);
        uint256 expectedStartTime = block.timestamp;
        uint256 expectedStopTime;
        unchecked {
            expectedStopTime = block.timestamp + totalDuration;
        }
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, expectedStartTime);
        assertEq(actualStream.stopTime, expectedStopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }
}
