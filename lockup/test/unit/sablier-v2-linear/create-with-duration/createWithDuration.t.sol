// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__CreateWithDuration is SablierV2LinearUnitTest {
    /// @dev it should revert due to the start time being greater than the stop time.
    function testCannotCreateWithDuration__CliffDurationCalculationOverflows(uint256 cliffDuration) external {
        vm.assume(cliffDuration > UINT256_MAX - block.timestamp);
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
        sablierV2Linear.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
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
    function testCannotCreateWithDuration__TotalDurationCalculationOverflow(
        uint256 cliffDuration,
        uint256 totalDuration
    ) external CliffDurationCalculationDoesNotOverflow {
        vm.assume(cliffDuration <= UINT256_MAX - block.timestamp);
        vm.assume(totalDuration > UINT256_MAX - block.timestamp);
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
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
    }

    modifier TotalDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should create the stream with duration.
    function testCreateWithDuration(uint256 cliffDuration, uint256 totalDuration)
        external
        CliffDurationCalculationDoesNotOverflow
        TotalDurationCalculationDoesNotOverflow
    {
        vm.assume(cliffDuration <= totalDuration);
        vm.assume(totalDuration <= UINT256_MAX - block.timestamp);
        uint256 cliffTime;
        uint256 stopTime;
        unchecked {
            cliffTime = block.timestamp + cliffDuration;
            stopTime = block.timestamp + totalDuration;
        }
        uint256 daiStreamId = sablierV2Linear.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }
}
