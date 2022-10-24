// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";
import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Create is SablierV2LinearUnitTest {
    /// @dev it should revert.
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

    modifier RecipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__DepositAmountZero() external RecipientNonZeroAddress {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
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
    function testCannotCreate__StartTimeGreaterThanStopTime() external RecipientNonZeroAddress DepositAmountNotZero {
        uint256 startTime = daiStream.stopTime;
        uint256 stopTime = daiStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector, startTime, stopTime)
        );
        sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            startTime,
            daiStream.cliffTime,
            stopTime,
            daiStream.cancelable
        );
    }

    /// @dev it should create the stream.
    function testCreate__StartTimeEqualToStopTime() external RecipientNonZeroAddress DepositAmountNotZero {
        uint256 cliffTime = daiStream.startTime;
        uint256 stopTime = daiStream.startTime;
        uint256 daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            stopTime,
            daiStream.cancelable
        );

        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
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

    modifier StartTimeLessThanStopTime() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__StartTimeGreaterThanCliffTime()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanStopTime
    {
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
    function testCannotCreate__StartTimeEqualToCliffTime()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanStopTime
    {
        uint256 cliffTime = daiStream.startTime;
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

        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
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
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
    {
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
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
    {
        uint256 cliffTime = daiStream.stopTime;
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

        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
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
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
    {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
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
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
    {
        IERC20 token = IERC20(address(nonCompliantToken));

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

        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(address(actualStream.token), address(nonCompliantToken));
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
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = createDefaultUsdcStream();
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(usdcStreamId);
        ISablierV2Linear.Stream memory expectedStream = usdcStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token6Decimals__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanStopTime
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

    /// @dev it should emit a CreateStream event.
    function testCreate__Token6Decimals__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = usdcStream.sender;
        emit CreateStream(
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
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        // Make Alice the funder of the stream.
        changePrank(users.alice);
        uint256 daiStreamId = createDefaultDaiStream();

        // Run the test.
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token18Decimals__CallerNotSender__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanStopTime
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

    /// @dev  it should emit a CreateStream event.
    function testCreate__Token18Decimals__CallerNotSender__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanStopTime
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
        emit CreateStream(
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
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 daiStreamId = createDefaultDaiStream();
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(daiStream, createdStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token18Decimals__CallerSender__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanStopTime
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

    /// @dev it should emit a CreateStream event.
    function testCreate__Token18Decimals__CallerSender__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        StartTimeLessThanStopTime
        StartTimeLessThanCliffTime
        CliffLessThanStopTime
        TokenContract
        TokenCompliant
    {
        uint256 daiStreamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = daiStream.sender;
        emit CreateStream(
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
