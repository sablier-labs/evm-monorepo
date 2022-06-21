// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";
import { SablierV2Cliff } from "@sablier/v2-core/SablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__Create is SablierV2CliffUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__DepositAmountZero() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
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
        sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            startTime,
            daiStream.cliffTime,
            stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the start time is equal to the stop time, it should create the stream.
    function testCreate__StartTimeEqualToStopTime() external {
        uint256 cliffTime = daiStream.startTime;
        uint256 stopTime = daiStream.startTime;
        uint256 streamId = sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            stopTime,
            daiStream.cancelable
        );
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(daiStream.sender, createdStream.sender);
        assertEq(daiStream.recipient, createdStream.recipient);
        assertEq(daiStream.depositAmount, createdStream.depositAmount);
        assertEq(daiStream.token, createdStream.token);
        assertEq(daiStream.startTime, createdStream.startTime);
        assertEq(cliffTime, createdStream.cliffTime);
        assertEq(stopTime, createdStream.stopTime);
        assertEq(daiStream.cancelable, createdStream.cancelable);
        assertEq(daiStream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the start time is greater than the cliff time, is should revert.
    function testCannotCreate__StartTimeGreaterThanCliffTime() external {
        uint256 startTime = daiStream.cliffTime;
        uint256 cliffTime = daiStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Cliff.SablierV2Cliff__StartTimeGreaterThanCliffTime.selector,
                startTime,
                cliffTime
            )
        );
        sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the cliff time is equal to the stop time, it should create the stream.
    function testCreate__CliffTimeEqualStopTime() external {
        uint256 cliffTime = daiStream.stopTime;
        uint256 streamId = sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(daiStream.sender, createdStream.sender);
        assertEq(daiStream.recipient, createdStream.recipient);
        assertEq(daiStream.depositAmount, createdStream.depositAmount);
        assertEq(daiStream.token, createdStream.token);
        assertEq(daiStream.startTime, createdStream.startTime);
        assertEq(cliffTime, createdStream.cliffTime);
        assertEq(daiStream.stopTime, createdStream.stopTime);
        assertEq(daiStream.cancelable, createdStream.cancelable);
        assertEq(daiStream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the cliff time is greater than the stop time, is should revert.
    function testCannotCreate__CliffTimeGreaterThanStopTime() external {
        uint256 cliffTime = daiStream.stopTime;
        uint256 stopTime = daiStream.cliffTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Cliff.SablierV2Cliff__CliffTimeGreaterThanStopTime.selector,
                cliffTime,
                stopTime
            )
        );
        sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the cliff time is the equal to the stop time, it should create the stream.
    function testCreate__CliffTimeEqualToStopTime() external {
        uint256 cliffTime = daiStream.stopTime;
        uint256 streamId = sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.stopTime,
            cliffTime,
            daiStream.cancelable
        );
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(daiStream.sender, createdStream.sender);
        assertEq(daiStream.recipient, createdStream.recipient);
        assertEq(daiStream.depositAmount, createdStream.depositAmount);
        assertEq(daiStream.token, createdStream.token);
        assertEq(daiStream.startTime, createdStream.startTime);
        assertEq(cliffTime, createdStream.cliffTime);
        assertEq(daiStream.stopTime, createdStream.stopTime);
        assertEq(daiStream.cancelable, createdStream.cancelable);
        assertEq(daiStream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the stream.
    function testCreate__TokenMissingReturnValue() external {
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(daiStream.sender, createdStream.sender);
        assertEq(daiStream.recipient, createdStream.recipient);
        assertEq(daiStream.depositAmount, createdStream.depositAmount);
        assertEq(address(nonStandardToken), address(createdStream.token));
        assertEq(daiStream.startTime, createdStream.startTime);
        assertEq(daiStream.cliffTime, createdStream.cliffTime);
        assertEq(daiStream.stopTime, createdStream.stopTime);
        assertEq(daiStream.cancelable, createdStream.cancelable);
        assertEq(daiStream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should create the stream.
    function testCreate__6Decimals() external {
        uint256 streamId = createDefaultUsdcStream();
        ISablierV2Cliff.Stream memory actualStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream = usdcStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should bump the next stream id.
    function testCreate__6Decimals__NextStreamId() external {
        uint256 nextStreamId = sablierV2Cliff.nextStreamId();
        createDefaultUsdcStream();
        uint256 actualNextStreamId = sablierV2Cliff.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should emit a CreateStream event.
    function testCreate__6Decimals__Event() external {
        uint256 streamId = sablierV2Cliff.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            usdcStream.sender,
            usdcStream.sender,
            usdcStream.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.startTime,
            usdcStream.cliffTime,
            usdcStream.stopTime,
            usdcStream.cancelable
        );
        createDefaultUsdcStream();
    }

    /// @dev When all checks pass and the token has 18 decimals, it should create the stream.
    function testCreate__18Decimals() external {
        uint256 streamId = createDefaultDaiStream();
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(daiStream, createdStream);
    }

    /// @dev When all checks pass and the token has 18 decimals, it should bump the next stream id.
    function testCreate__18Decimals__NextStreamId() external {
        uint256 nextStreamId = sablierV2Cliff.nextStreamId();
        createDefaultDaiStream();
        uint256 actualNextStreamId = sablierV2Cliff.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass and the token has 18 decimals, it should emit a CreateStream event.
    function testCreate__18Decimals__Event() external {
        uint256 streamId = sablierV2Cliff.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        createDefaultDaiStream();
    }
}
