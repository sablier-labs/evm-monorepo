// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract CreateWithDuration__Test is SablierV2LinearTest {
    /// @dev it should revert due to the start time being greater than the cliff time.
    function testCannotCreateWithDuration__CliffDurationCalculationOverflows(uint40 cliffDuration) external {
        vm.assume(cliffDuration > UINT40_MAX - block.timestamp);
        uint40 totalDuration = cliffDuration;
        uint40 cliffTime;
        uint40 stopTime;
        unchecked {
            cliffTime = uint40(block.timestamp) + cliffDuration;
            stopTime = cliffTime;
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Linear__StartTimeGreaterThanCliffTime.selector,
                uint40(block.timestamp),
                stopTime
            )
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
    function testCannotCreateWithDuration__TotalDurationCalculationOverflows(
        uint40 cliffDuration,
        uint40 totalDuration
    ) external CliffDurationCalculationDoesNotOverflow {
        uint40 startTime = uint40(block.timestamp);
        vm.assume(cliffDuration <= UINT40_MAX - startTime);
        vm.assume(totalDuration > UINT40_MAX - startTime);
        uint40 cliffTime;
        uint40 stopTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
            stopTime = startTime + totalDuration;
        }
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__CliffTimeGreaterThanStopTime.selector, cliffTime, stopTime)
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
    function testCreateWithDuration(
        uint40 cliffDuration,
        uint40 totalDuration
    ) external CliffDurationCalculationDoesNotOverflow TotalDurationCalculationDoesNotOverflow {
        vm.assume(cliffDuration <= totalDuration);
        vm.assume(totalDuration <= UINT40_MAX - block.timestamp);
        uint40 cliffTime;
        uint40 stopTime;
        unchecked {
            cliffTime = uint40(block.timestamp) + cliffDuration;
            stopTime = uint40(block.timestamp) + totalDuration;
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
        assertEq(actualStream.isEntity, daiStream.isEntity);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        assertEq(actualRecipient, users.recipient);
    }
}
