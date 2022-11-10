// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";
import { Errors } from "@sablier/v2-core/libraries/Errors.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__CreateWithDuration is SablierV2LinearUnitTest {
    /// @dev it should revert due to the start time being greater than the stop time.
    function testCannotCreateWithDuration__CliffDurationCalculationOverflows(uint64 cliffDuration) external {
        vm.assume(cliffDuration > UINT64_MAX - block.timestamp);
        uint64 totalDuration = cliffDuration;
        uint64 cliffTime;
        uint64 stopTime;
        unchecked {
            cliffTime = uint64(block.timestamp) + cliffDuration;
            stopTime = cliffTime;
        }
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__StartTimeGreaterThanStopTime.selector, block.timestamp, stopTime)
        );
        sablierV2Linear.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
    }

    modifier CliffDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev When the total duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__TotalDurationCalculationOverflows(uint64 cliffDuration, uint64 totalDuration)
        external
        CliffDurationCalculationDoesNotOverflow
    {
        vm.assume(cliffDuration <= UINT64_MAX - block.timestamp);
        vm.assume(totalDuration > UINT64_MAX - block.timestamp);
        uint64 stopTime;
        unchecked {
            stopTime = uint64(block.timestamp) + totalDuration;
        }
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__StartTimeGreaterThanStopTime.selector, block.timestamp, stopTime)
        );
        sablierV2Linear.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
    }

    modifier TotalDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should create the stream with duration.
    function testCreateWithDuration(uint64 cliffDuration, uint64 totalDuration)
        external
        CliffDurationCalculationDoesNotOverflow
        TotalDurationCalculationDoesNotOverflow
    {
        vm.assume(cliffDuration <= totalDuration);
        vm.assume(totalDuration <= UINT64_MAX - block.timestamp);
        uint64 cliffTime;
        uint64 stopTime;
        unchecked {
            cliffTime = uint64(block.timestamp) + cliffDuration;
            stopTime = uint64(block.timestamp) + totalDuration;
        }
        uint256 daiStreamId = sablierV2Linear.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );

        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        assertEq(actualRecipient, users.recipient);
    }
}
