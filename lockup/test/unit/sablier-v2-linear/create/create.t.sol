// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";
import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";

import { DSTest } from "ds-test/test.sol";
import { stdError } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Create__UnitTest is SablierV2LinearUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Linear.create(
            stream.sender,
            recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.stopTime,
            stream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__DepositAmountZero() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            depositAmount,
            stream.token,
            stream.startTime,
            stream.stopTime,
            stream.cancelable
        );
    }

    /// @dev When the start time is greater than the stop time, it should revert.
    function testCannotCreate__StartTimeGreaterThanStopTime() external {
        uint256 startTime = stream.stopTime;
        uint256 stopTime = stream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector, startTime, stopTime)
        );
        sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            startTime,
            stopTime,
            stream.cancelable
        );
    }

    /// @dev When the start time is the equal to the stop time, it should create the stream.
    function testCreate__StopTimeEqualToStartTime() external {
        uint256 stopTime = stream.startTime;
        uint256 streamId = sablierV2Linear.nextStreamId();
        sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stopTime,
            stream.cancelable
        );
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(stream.token, createdStream.token);
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(stopTime, createdStream.stopTime);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            token,
            stream.startTime,
            stream.stopTime,
            stream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the stream.
    function testCreate__TokenMissingReturnValue() external {
        nonStandardToken.mint(users.sender, DEFAULT_DEPOSIT_AMOUNT);
        nonStandardToken.approve(address(sablierV2Linear), DEFAULT_DEPOSIT_AMOUNT);
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Linear.nextStreamId();
        sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            token,
            stream.startTime,
            stream.stopTime,
            stream.cancelable
        );

        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(address(nonStandardToken), address(createdStream.token));
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(stream.stopTime, createdStream.stopTime);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When all checks pass, it should create the stream.
    function testCreate() external {
        uint256 streamId = createDefaultStream();
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(stream, createdStream);
    }

    /// @dev When all checks pass, it should bump the next stream id.
    function testCreate__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        createDefaultStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        assertEq(expectedNextStreamId, actualNextStreamId);
    }

    /// @dev When all checks pass, it should emit a CreateStream event.
    function testCreate__Event() external {
        uint256 streamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.stopTime,
            stream.cancelable
        );
        createDefaultStream();
    }
}
