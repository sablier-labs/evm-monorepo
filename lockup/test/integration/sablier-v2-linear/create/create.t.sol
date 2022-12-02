// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract Create__Test is SablierV2LinearTest {
    /// @dev it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(Errors.SablierV2__RecipientZeroAddress.selector);
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

    modifier RecipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__DepositAmountZero() external RecipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2__DepositAmountZero.selector);
        uint128 depositAmount = 0;
        sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    modifier DepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__StartTimeGreaterThanCliffTime() external RecipientNonZeroAddress DepositAmountNotZero {
        uint40 startTime = daiStream.cliffTime;
        uint40 cliffTime = daiStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__StartTimeGreaterThanCliffTime.selector, startTime, cliffTime)
        );
        sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    /// @dev it should create the stream.
    function testCannotCreate__StartTimeEqualToCliffTime() external RecipientNonZeroAddress DepositAmountNotZero {
        uint40 cliffTime = daiStream.startTime;
        uint256 daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        assertEq(actualRecipient, users.recipient);
    }

    modifier StartTimeLessThanCliffTime() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__CliffTimeGreaterThanStopTime()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
    {
        uint40 cliffTime = daiStream.stopTime;
        uint40 stopTime = daiStream.cliffTime;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear__CliffTimeGreaterThanStopTime.selector, cliffTime, stopTime)
        );
        sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            stopTime,
            daiStream.cancelable
        );
    }

    /// @dev it should create the stream.
    function testCreate__CliffTimeEqualToStopTime()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
    {
        uint40 cliffTime = daiStream.stopTime;
        uint256 daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        assertEq(actualRecipient, users.recipient);
    }

    modifier CliffLessThanStopTime() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__TokenNotContract()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
    {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        address token = address(6174);
        sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    modifier TokenContract() {
        _;
    }

    /// @dev it should create the stream.
    function testCreate__TokenMissingReturnValue()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
    {
        address token = address(nonCompliantToken);

        uint256 daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, address(nonCompliantToken));
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, daiStream.cliffTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        assertEq(actualRecipient, users.recipient);
    }

    modifier TokenCompliant() {
        _;
    }

    /// @dev  it should create the stream.
    function testCreate__Token6Decimals()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = createDefaultUsdcStream();
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(usdcStreamId);
        DataTypes.LinearStream memory expectedStream = usdcStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token6Decimals__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        createDefaultUsdcStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateLinearStream event.
    function testCreate__Token6Decimals__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = usdcStream.sender;
        emit Events.CreateLinearStream(
            usdcStreamId,
            funder,
            usdcStream.sender,
            users.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.startTime,
            usdcStream.cliffTime,
            usdcStream.stopTime,
            usdcStream.cancelable
        );
        createDefaultUsdcStream();
    }

    /// @dev it should create the stream.
    function testCreate___Token18Decimals__CallerNotSender()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        // Make Alice the funder of the stream.
        changePrank(users.alice);
        uint256 daiStreamId = createDefaultDaiStream();

        // Run the test.
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token18Decimals__CallerNotSender__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();

        // Make Alice the funder of the stream.
        changePrank(users.alice);
        createDefaultDaiStream();

        // Run the test.
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev  it should emit a CreateLinearStream event.
    function testCreate__Token18Decimals__CallerNotSender__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        // Make Alice the funder of the stream.
        changePrank(users.alice);

        // Run the test.
        uint256 daiStreamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = users.alice;
        emit Events.CreateLinearStream(
            daiStreamId,
            funder,
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        createDefaultDaiStream();
    }

    /// @dev it should create the stream.
    function testCreate__Token18Decimals__CallerSender()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 daiStreamId = createDefaultDaiStream();
        DataTypes.LinearStream memory createdStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(daiStream, createdStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token18Decimals__CallerSender__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        createDefaultDaiStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateLinearStream event.
    function testCreate__Token18Decimals__CallerSender__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 daiStreamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = daiStream.sender;
        emit Events.CreateLinearStream(
            daiStreamId,
            funder,
            daiStream.sender,
            users.recipient,
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
