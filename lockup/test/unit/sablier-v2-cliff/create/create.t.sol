// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";
import { SablierV2Cliff } from "@sablier/v2-core/SablierV2Cliff.sol";

import { DSTest } from "ds-test/test.sol";
import { stdError } from "forge-std/stdlib.sol";
import { Vm } from "forge-std/Vm.sol";

import { SablierV2CliffUnitTest } from "../../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__Create__UnitTest is SablierV2CliffUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Cliff.create(
            cliffStream.sender,
            recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            cliffStream.startTime,
            cliffStream.stopTime,
            cliffStream.cliffTime,
            cliffStream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__DepositAmountZero() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            depositAmount,
            cliffStream.token,
            cliffStream.startTime,
            cliffStream.stopTime,
            cliffStream.cliffTime,
            cliffStream.cancelable
        );
    }

    /// @dev When the start time is greater than the stop time, it should revert.
    function testCannotCreate__StartTimeGreaterThanStopTime() external {
        uint256 startTime = cliffStream.stopTime;
        uint256 stopTime = cliffStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector, startTime, stopTime)
        );
        sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            startTime,
            stopTime,
            cliffStream.cliffTime,
            cliffStream.cancelable
        );
    }

    /// @dev When the start time is greater than cliff time, is should revert.
    function testCannotCreate__StartTimeGreaterThanCliffTime() external {
        uint256 startTime = cliffStream.cliffTime;
        uint256 cliffTime = cliffStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Cliff.SablierV2Cliff__StartTimeGreaterThanCliffTime.selector,
                startTime,
                cliffTime
            )
        );
        sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            startTime,
            cliffStream.stopTime,
            cliffTime,
            cliffStream.cancelable
        );
    }

    /// @dev When the cliff time is greater than stop time, is should revert.
    function testCannotCreate__CliffTimeGreaterThanStopTime() external {
        uint256 cliffTime = cliffStream.stopTime;
        uint256 stopTime = cliffStream.cliffTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Cliff.SablierV2Cliff__CliffTimeGreaterThanStopTime.selector,
                stopTime,
                cliffTime
            )
        );
        sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            cliffStream.startTime,
            stopTime,
            cliffTime,
            cliffStream.cancelable
        );
    }

    /// @dev When the start time is the equal to the stop time, it should create the cliff stream.
    function testCreate__StopTimeEqualToStartTimeAndCliffTime() external {
        uint256 stopTime = cliffStream.startTime;
        uint256 cliffTime = cliffStream.startTime;
        uint256 streamId = sablierV2Cliff.nextStreamId();
        sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            cliffStream.startTime,
            stopTime,
            cliffTime,
            cliffStream.cancelable
        );
        ISablierV2Cliff.CliffStream memory createdCliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(cliffStream.sender, createdCliffStream.sender);
        assertEq(cliffStream.recipient, createdCliffStream.recipient);
        assertEq(cliffStream.depositAmount, createdCliffStream.depositAmount);
        assertEq(cliffStream.token, createdCliffStream.token);
        assertEq(cliffStream.startTime, createdCliffStream.startTime);
        assertEq(stopTime, createdCliffStream.stopTime);
        assertEq(cliffTime, createdCliffStream.cliffTime);
        assertEq(cliffStream.cancelable, createdCliffStream.cancelable);
        assertEq(cliffStream.withdrawnAmount, createdCliffStream.withdrawnAmount);
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(0)));
        IERC20 token = IERC20(address(0));
        sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            token,
            cliffStream.startTime,
            cliffStream.stopTime,
            cliffStream.cliffTime,
            cliffStream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the cliff stream.
    function testCreate__TokenMissingReturnValue() external {
        nonStandardToken.mint(users.sender, DEFAULT_DEPOSIT);
        nonStandardToken.approve(address(sablierV2Cliff), DEFAULT_DEPOSIT);
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Cliff.nextStreamId();
        sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            token,
            cliffStream.startTime,
            cliffStream.stopTime,
            cliffStream.cliffTime,
            cliffStream.cancelable
        );

        ISablierV2Cliff.CliffStream memory createdCliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(cliffStream.sender, createdCliffStream.sender);
        assertEq(cliffStream.recipient, createdCliffStream.recipient);
        assertEq(cliffStream.depositAmount, createdCliffStream.depositAmount);
        assertEq(address(nonStandardToken), address(createdCliffStream.token));
        assertEq(cliffStream.startTime, createdCliffStream.startTime);
        assertEq(cliffStream.stopTime, createdCliffStream.stopTime);
        assertEq(cliffStream.cliffTime, createdCliffStream.cliffTime);
        assertEq(cliffStream.cancelable, createdCliffStream.cancelable);
        assertEq(cliffStream.withdrawnAmount, createdCliffStream.withdrawnAmount);
    }

    /// @dev When all checks pass, it should create the cliff stream.
    function testCreate() external {
        uint256 streamId = createDefaultCliffStream();
        ISablierV2Cliff.CliffStream memory createdCliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(cliffStream, createdCliffStream);
    }

    /// @dev When all checks pass, it should bump the next stream id.
    function testCreate__NextStreamId() external {
        uint256 nextStreamId = sablierV2Cliff.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        createDefaultCliffStream();
        uint256 actualNextStreamId = sablierV2Cliff.nextStreamId();
        assertEq(expectedNextStreamId, actualNextStreamId);
    }

    /// @dev When all checks pass, it should emit a CreateCliffStream event.
    function testCreate__Event() external {
        uint256 streamId = sablierV2Cliff.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateCliffStream(
            streamId,
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            cliffStream.startTime,
            cliffStream.stopTime,
            cliffStream.cliffTime,
            cliffStream.cancelable
        );
        createDefaultCliffStream();
    }
}
