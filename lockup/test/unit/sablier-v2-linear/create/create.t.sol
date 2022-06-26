// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";
import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__Create is SablierV2LinearUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.sender,
            recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__DepositAmountZero() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the start time is greater than the stop time, it should revert.
    function testCannotCreate__StartTimeGreaterThanStopTime() external {
        uint256 startTime = daiStream.stopTime;
        uint256 stopTime = daiStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector, startTime, stopTime)
        );
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            startTime,
            stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the start time is the equal to the stop time, it should create the stream.
    function testCreate__StartTimeEqualToStopTime() external {
        uint256 stopTime = daiStream.startTime;
        uint256 streamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            stopTime,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(daiStream.sender, createdStream.sender);
        assertEq(daiStream.recipient, createdStream.recipient);
        assertEq(daiStream.depositAmount, createdStream.depositAmount);
        assertEq(daiStream.token, createdStream.token);
        assertEq(daiStream.startTime, createdStream.startTime);
        assertEq(stopTime, createdStream.stopTime);
        assertEq(daiStream.cancelable, createdStream.cancelable);
        assertEq(daiStream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the stream.
    function testCreate__TokenMissingReturnValue() external {
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(daiStream.sender, createdStream.sender);
        assertEq(daiStream.recipient, createdStream.recipient);
        assertEq(daiStream.depositAmount, createdStream.depositAmount);
        assertEq(address(nonStandardToken), address(createdStream.token));
        assertEq(daiStream.startTime, createdStream.startTime);
        assertEq(daiStream.stopTime, createdStream.stopTime);
        assertEq(daiStream.cancelable, createdStream.cancelable);
        assertEq(daiStream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should create the stream.
    function testCreate__6Decimals() external {
        uint256 streamId = createDefaultUsdcStream();
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(streamId);
        ISablierV2Linear.Stream memory expectedStream = usdcStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should bump the next stream id.
    function testCreate__6Decimals__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        createDefaultUsdcStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should emit a CreateStream event.
    function testCreate__6Decimals__Event() external {
        uint256 streamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            usdcStream.sender,
            usdcStream.sender,
            usdcStream.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.startTime,
            usdcStream.stopTime,
            usdcStream.cancelable
        );
        createDefaultUsdcStream();
    }

    /// @dev When all checks pass and the token has 18 decimals, it should create the stream.
    function testCreate__18Decimals() external {
        uint256 streamId = createDefaultDaiStream();
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(daiStream, createdStream);
    }

    /// @dev When all checks pass and the token has 18 decimals, it should bump the next stream id.
    function testCreate__18Decimals__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        createDefaultDaiStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass and the token has 18 decimals, it should emit a CreateStream event.
    function testCreate__18Decimals__Event() external {
        uint256 streamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        createDefaultDaiStream();
    }
}
