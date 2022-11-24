// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";
import { Errors } from "@sablier/v2-core/libraries/Errors.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract CreateWithDuration__Test is SablierV2LinearTest {
    /// @dev it should revert due to the start time being greater than the cliff time.
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
            abi.encodeWithSelector(
                Errors.SablierV2Linear__StartTimeGreaterThanCliffTime.selector,
                uint64(block.timestamp),
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
    function testCannotCreateWithDuration__TotalDurationCalculationOverflows(uint64 cliffDuration, uint64 totalDuration)
        external
        CliffDurationCalculationDoesNotOverflow
    {
        uint64 startTime = uint64(block.timestamp);
        vm.assume(cliffDuration <= UINT64_MAX - startTime);
        vm.assume(totalDuration > UINT64_MAX - startTime);
        uint64 cliffTime;
        uint64 stopTime;
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
