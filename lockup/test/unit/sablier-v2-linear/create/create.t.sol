// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";
import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";

import { DSTest } from "ds-test/test.sol";
import { stdError } from "forge-std/stdlib.sol";
import { Vm } from "forge-std/Vm.sol";

import { SablierV2LinearUnitTest } from "../../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Create__UnitTest is SablierV2LinearUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Linear.create(
            linearStream.sender,
            recipient,
            linearStream.depositAmount,
            linearStream.token,
            linearStream.startTime,
            linearStream.stopTime,
            linearStream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__DepositAmountZero() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            depositAmount,
            linearStream.token,
            linearStream.startTime,
            linearStream.stopTime,
            linearStream.cancelable
        );
    }

    /// @dev When the start time is greater than the stop time, it should revert.
    function testCannotCreate__StartTimeGreaterThanStopTime() external {
        uint256 startTime = linearStream.stopTime;
        uint256 stopTime = linearStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector, startTime, stopTime)
        );
        sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            startTime,
            stopTime,
            linearStream.cancelable
        );
    }

    /// @dev When the start time is the equal to the stop time, it should create the linear stream.
    function testCreate__StopTimeEqualToStartTime() external {
        uint256 stopTime = linearStream.startTime;
        uint256 streamId = sablierV2Linear.nextStreamId();
        sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            linearStream.startTime,
            stopTime,
            linearStream.cancelable
        );
        ISablierV2Linear.LinearStream memory createdLinearStream = sablierV2Linear.getLinearStream(streamId);
        assertEq(linearStream.sender, createdLinearStream.sender);
        assertEq(linearStream.recipient, createdLinearStream.recipient);
        assertEq(linearStream.depositAmount, createdLinearStream.depositAmount);
        assertEq(linearStream.token, createdLinearStream.token);
        assertEq(linearStream.startTime, createdLinearStream.startTime);
        assertEq(stopTime, createdLinearStream.stopTime);
        assertEq(linearStream.cancelable, createdLinearStream.cancelable);
        assertEq(linearStream.withdrawnAmount, createdLinearStream.withdrawnAmount);
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(0)));
        IERC20 token = IERC20(address(6174));
        sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            token,
            linearStream.startTime,
            linearStream.stopTime,
            linearStream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the linear stream.
    function testCreate__TokenMissingReturnValue() external {
        nonStandardToken.mint(users.sender, DEFAULT_DEPOSIT);
        nonStandardToken.approve(address(sablierV2Linear), DEFAULT_DEPOSIT);
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Linear.nextStreamId();
        sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            token,
            linearStream.startTime,
            linearStream.stopTime,
            linearStream.cancelable
        );

        ISablierV2Linear.LinearStream memory createdLinearStream = sablierV2Linear.getLinearStream(streamId);
        assertEq(linearStream.sender, createdLinearStream.sender);
        assertEq(linearStream.recipient, createdLinearStream.recipient);
        assertEq(linearStream.depositAmount, createdLinearStream.depositAmount);
        assertEq(address(nonStandardToken), address(createdLinearStream.token));
        assertEq(linearStream.startTime, createdLinearStream.startTime);
        assertEq(linearStream.stopTime, createdLinearStream.stopTime);
        assertEq(linearStream.cancelable, createdLinearStream.cancelable);
        assertEq(linearStream.withdrawnAmount, createdLinearStream.withdrawnAmount);
    }

    /// @dev When all checks pass, it should create the linear stream.
    function testCreate() external {
        uint256 streamId = createDefaultLinearStream();
        ISablierV2Linear.LinearStream memory createdLinearStream = sablierV2Linear.getLinearStream(streamId);
        assertEq(linearStream, createdLinearStream);
    }

    /// @dev When all checks pass, it should bump the next stream id.
    function testCreate__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        createDefaultLinearStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        assertEq(expectedNextStreamId, actualNextStreamId);
    }

    /// @dev When all checks pass, it should emit a CreateLinearStream event.
    function testCreate__Event() external {
        uint256 streamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateLinearStream(
            streamId,
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            linearStream.startTime,
            linearStream.stopTime,
            linearStream.cancelable
        );
        createDefaultLinearStream();
    }
}
