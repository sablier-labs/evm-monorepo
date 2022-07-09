// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__CancelAll is SablierV2LinearUnitTest {
    uint256[] internal defaultStreamIds;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultDaiStream());
        defaultStreamIds.push(createDefaultDaiStream());
    }

    /// @dev it should do nothing.
    function testCannotCancelAll__OnlyNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId);
        sablierV2Linear.cancelAll(streamIds);
    }

    /// @dev it should cancel and delete the non existent streams.
    function testCannotCancelAll__SomeNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonStreamId);
        sablierV2Linear.cancelAll(streamIds);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier OnlyExistentStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedAllStreams() external OnlyExistentStreams {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedSomeStreams() external OnlyExistentStreams {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Create a stream with Eve as the sender.
        uint256 eveStreamId = sablierV2Linear.create(
            users.eve,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.cancelAll(streamIds);
    }

    /// @dev it should cancel and delete the streams.
    function testCancelAll__CallerRecipientAllStreams() external OnlyExistentStreams {
        // Make the recipient the `msg.sender` in this test case.
        changePrank(users.recipient);

        // Run the test.
        sablierV2Linear.cancelAll(defaultStreamIds);

        ISablierV2Linear.Stream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        ISablierV2Linear.Stream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);
    }

    modifier CallerSenderAllStreams() {
        _;
    }

    /// @dev it should do nothing.
    function testCannotCancelAll__AllStreamsNonCancelable() external OnlyExistentStreams CallerSenderAllStreams {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        uint256[] memory nonCancelableStreamIds = createDynamicArray(nonCancelableDaiStreamId);
        sablierV2Linear.cancelAll(nonCancelableStreamIds);
    }

    /// @dev it should cancel and delete the cancelable streams.
    function testCannotCancelAll__SomeStreamsNonCancelable() external OnlyExistentStreams CallerSenderAllStreams {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonCancelableDaiStreamId);
        sablierV2Linear.cancelAll(streamIds);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier AllStreamsCancelable() {
        _;
    }

    /// @dev it should cancel and delete the streams.
    function testCancelAll__AllStreamsEnded() external OnlyExistentStreams CallerSenderAllStreams AllStreamsCancelable {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        sablierV2Linear.cancelAll(defaultStreamIds);

        ISablierV2Linear.Stream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        ISablierV2Linear.Stream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);
    }

    /// @dev it should emit multiple Cancel events.
    function testCancelAll__AllStreamsEnded__Events()
        external
        OnlyExistentStreams
        CallerSenderAllStreams
        AllStreamsCancelable
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        uint256 withdrawAmount = daiStream.depositAmount;
        uint256 returnAmount = 0;

        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[0], daiStream.recipient, withdrawAmount, returnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[1], daiStream.recipient, withdrawAmount, returnAmount);

        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], defaultStreamIds[1]);
        sablierV2Linear.cancelAll(streamIds);
    }

    /// @dev it should cancel and delete the streams.
    function testCancelAll__AllStreamsOngoing()
        external
        OnlyExistentStreams
        CallerSenderAllStreams
        AllStreamsCancelable
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.cancelAll(defaultStreamIds);

        ISablierV2Linear.Stream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        ISablierV2Linear.Stream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);
    }

    /// @dev it should emit multiple Cancel events.
    function testCancelAll__AllStreamsOngoing__Events()
        external
        OnlyExistentStreams
        CallerSenderAllStreams
        AllStreamsCancelable
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT_DAI;
        uint256 returnAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;

        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[0], daiStream.recipient, withdrawAmount, returnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[1], daiStream.recipient, withdrawAmount, returnAmount);

        sablierV2Linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should cancel and delete the streams.
    function testCancelAll__SomeStreamsEndedSomeStreamsOngoing()
        external
        OnlyExistentStreams
        CallerSenderAllStreams
        AllStreamsCancelable
    {
        // Use the first default stream as the ongoing daiStream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended dai stream.
        uint256 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            earlyStopTime,
            daiStream.cancelable
        );

        // Warp to the end of the first daiStream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(ongoingStreamId, endedDaiStreamId);
        sablierV2Linear.cancelAll(streamIds);

        ISablierV2Linear.Stream memory deletedOngoingStream = sablierV2Linear.getStream(ongoingStreamId);
        ISablierV2Linear.Stream memory deletedEndedStream = sablierV2Linear.getStream(endedDaiStreamId);
        ISablierV2Linear.Stream memory expectedStream;

        assertEq(deletedOngoingStream, expectedStream);
        assertEq(deletedEndedStream, expectedStream);
    }

    /// @dev it should emit multiple Cancel events.
    function testCancelAll__SomeStreamsEndedSomeStreamsOngoing__Events()
        external
        OnlyExistentStreams
        CallerSenderAllStreams
        AllStreamsCancelable
    {
        // Use the first default stream as the ongoing daiStream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended dai stream.
        uint256 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            earlyStopTime,
            daiStream.cancelable
        );

        // Warp to the end of the first daiStream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256 endedWithdrawAmount = daiStream.depositAmount;
        uint256 endedReturnAmount = 0;
        uint256 ongoingWithdrawAmount = WITHDRAW_AMOUNT_DAI;
        uint256 ongoingReturnAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;

        vm.expectEmit(true, true, false, true);
        emit Cancel(endedDaiStreamId, daiStream.recipient, endedWithdrawAmount, endedReturnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(ongoingStreamId, daiStream.recipient, ongoingWithdrawAmount, ongoingReturnAmount);

        uint256[] memory streamIds = createDynamicArray(endedDaiStreamId, ongoingStreamId);
        sablierV2Linear.cancelAll(streamIds);
    }
}
