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
        sablierV2Linear.create(
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
        sablierV2Linear.create(
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
        uint256 streamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            stopTime,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
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
                ISablierV2Linear.SablierV2Linear__StartTimeGreaterThanCliffTime.selector,
                startTime,
                cliffTime
            )
        );
        sablierV2Linear.create(
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

    /// @dev When the cliff time is greater than the stop time, is should revert.
    function testCannotCreate__CliffTimeGreaterThanStopTime() external {
        uint256 cliffTime = daiStream.stopTime;
        uint256 stopTime = daiStream.cliffTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Linear.SablierV2Linear__CliffTimeGreaterThanStopTime.selector,
                cliffTime,
                stopTime
            )
        );
        sablierV2Linear.create(
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

    /// @dev When the cliff time is equal to the stop time, it should create the stream.
    function testCreate__CliffTimeEqualToStopTime() external {
        uint256 cliffTime = daiStream.stopTime;
        uint256 streamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(streamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Linear.create(
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

        uint256 streamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
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
        address funder = usdcStream.sender;
        emit CreateStream(
            streamId,
            funder,
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

    /// @dev When all checks pass, the token has 18 decimals and the caller is the sender of the stream,
    /// it should create the stream.
    function testCreate__18Decimals__CallerSender() external {
        uint256 streamId = createDefaultDaiStream();
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(daiStream, createdStream);
    }

    /// @dev When all checks pass and the token has 18 decimals and the caller is the sender of the stream,
    /// it should bump the next stream id.
    function testCreate__18Decimals__CallerSender__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        createDefaultDaiStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass, the token has 18 decimals and the caller is the sender of the stream,
    /// it should emit a CreateStream event.
    function testCreate__18Decimals__CallerSender__Event() external {
        uint256 streamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = daiStream.sender;
        emit CreateStream(
            streamId,
            funder,
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

    /// @dev When all checks pass, the token has 18 decimals and the caller is not the sender of the stream,
    /// it should create the stream.
    function testCreate__18Decimals__CallerNotSender() external {
        // Make Alice the funder of the stream.
        changePrank(users.alice);
        uint256 streamId = createDefaultDaiStream();

        // Run the test.
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(streamId);
        ISablierV2Linear.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev When all checks pass, the token has 18 decimals and the caller is not the sender of the stream,
    /// it should bump the next stream id.
    function testCreate__18Decimals__CallerNotSender__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();

        // Make Alice the funder of the stream.
        changePrank(users.alice);
        createDefaultDaiStream();

        // Run the test.
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass, the token has 18 decimals and the caller is not the sender of the stream,
    /// it should emit a CreateStream event.
    function testCreate__18Decimals__CallerNotSender__Event() external {
        // Make Alice the funder of the stream.
        changePrank(users.alice);

        // Run the test.
        uint256 streamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = users.alice;
        emit CreateStream(
            streamId,
            funder,
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
