// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__CancelAll is SablierV2CliffUnitTest {
    uint256[] internal defaultStreamIds;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());
    }

    /// @dev When the stream ids array points only to non existing streams, it should revert.
    function testCannotCancelAll__OnlyNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId);
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When the stream ids array points to some non existing streams, it should revert.
    function testCannotCancelAll__SomeNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonStreamId);
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When the caller is neither the sender nor the recipient of any stream, it should revert.
    function testCannotCancelAll__CallerUnauthorized__AllStreams() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Cliff.cancelAll(defaultStreamIds);
    }

    /// @dev When the caller is neither the sender nor the recipient of some of the streams, it should revert.
    function testCannotCancelAll__CallerUnauthorized__SomeStreams() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Create a stream with Eve as the sender.
        uint256 streamIdEve = sablierV2Cliff.create(
            users.eve,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            stream.cancelable
        );

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(streamIdEve, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When the caller is the recipient of all the streams, it should cancel the streams.
    function testCancelAll__CallerRecipient__AllStreams() external {
        // Make the recipient the `msg.sender` in this test case.
        changePrank(users.recipient);

        // Run the test.
        sablierV2Cliff.cancelAll(defaultStreamIds);
    }

    /// @dev When all streams are non-cancelable, it should revert.
    function testCannotCancelAll__AllStreamsNonCancelable() external {
        // Create the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            cancelable
        );

        // Run the test.
        uint256[] memory nonCancelableStreamIds = createDynamicArray(nonCancelableStreamId);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableStreamId)
        );
        sablierV2Cliff.cancelAll(nonCancelableStreamIds);
    }

    /// @dev When some streams are non-cancelable, it should revert.
    function testCannotCancelAll__SomeNonCancelableStreams() external {
        // Create the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            cancelable
        );

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonCancelableStreamId);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableStreamId)
        );
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When all streams are ended, it should cancel the streams.
    function testCancelAll__AllStreamsEnded() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Cliff.cancelAll(defaultStreamIds);
    }

    /// @dev When all streams are ended, it should delete the streams.
    function testCancelAll__AllStreamsEnded__DeleteStreams() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Cliff.cancelAll(defaultStreamIds);

        ISablierV2Cliff.Stream memory actualStream0 = sablierV2Cliff.getStream(defaultStreamIds[0]);
        ISablierV2Cliff.Stream memory actualStream1 = sablierV2Cliff.getStream(defaultStreamIds[1]);
        ISablierV2Cliff.Stream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);
    }

    /// @dev When all streams are ended, it should emit multiple Cancel events.
    function testCancelAll__AllStreamsEnded__Events() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        uint256 returnAmount = 0;
        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[0], stream.recipient, withdrawAmount, returnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[1], stream.recipient, withdrawAmount, returnAmount);
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], defaultStreamIds[1]);
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When all streams are ongoing, it should cancel the streams.
    function testCancelAll__AllStreamsOngoing() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.cancelAll(defaultStreamIds);
    }

    /// @dev When all streams are ongoing, it should delete the streams.
    function testCancelAll__AllStreamsOngoing__DeleteStreams() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.cancelAll(defaultStreamIds);

        ISablierV2Cliff.Stream memory actualStream0 = sablierV2Cliff.getStream(defaultStreamIds[0]);
        ISablierV2Cliff.Stream memory actualStream1 = sablierV2Cliff.getStream(defaultStreamIds[1]);
        ISablierV2Cliff.Stream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);
    }

    /// @dev When all streams are ongoing, it should emit multiple Cancel events.
    function testCancelAll__AllStreamsOngoing__Events() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        uint256 returnAmount = stream.depositAmount - WITHDRAW_AMOUNT;
        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[0], stream.recipient, withdrawAmount, returnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[1], stream.recipient, withdrawAmount, returnAmount);
        sablierV2Cliff.cancelAll(defaultStreamIds);
    }

    /// @dev When some of the streams are ended and some are ongoing, it should cancel the streams.
    function testCancelAll__SomeStreamsEndedSomeStreamsOngoing() external {
        // Use the first default stream as the ongoing stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended stream.
        uint256 earlyStopTime = stream.startTime + TIME_OFFSET;
        uint256 endedStreamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            earlyStopTime,
            stream.cancelable
        );

        // Warp to the end of the first stream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(ongoingStreamId, endedStreamId);
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When some of the streams are ended and some are ongoing, it should delete the streams.
    function testCancelAll__SomeStreamsEndedSomeStreamsOngoing__DeleteStreams() external {
        // Use the first default stream as the ongoing stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended stream.
        uint256 earlyStopTime = stream.startTime + TIME_OFFSET;
        uint256 endedStreamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            earlyStopTime,
            stream.cancelable
        );

        // Warp to the end of the first stream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(ongoingStreamId, endedStreamId);
        sablierV2Cliff.cancelAll(streamIds);

        ISablierV2Cliff.Stream memory deletedOngoingStream = sablierV2Cliff.getStream(ongoingStreamId);
        ISablierV2Cliff.Stream memory deletedEndedStream = sablierV2Cliff.getStream(endedStreamId);
        ISablierV2Cliff.Stream memory expectedStream;

        assertEq(deletedOngoingStream, expectedStream);
        assertEq(deletedEndedStream, expectedStream);
    }

    /// @dev When some of the streams are ended and some are ongoing, it should emit multiple Cancel events.
    function testCancelAll__SomeStreamsEndedSomeStreamsOngoing__Events() external {
        // Use the first default stream as the ongoing stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended stream.
        uint256 earlyStopTime = stream.startTime + TIME_OFFSET;
        uint256 endedStreamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            earlyStopTime,
            stream.cancelable
        );

        // Warp to the end of the first stream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256 endedWithdrawAmount = stream.depositAmount;
        uint256 endedReturnAmount = 0;
        uint256 ongoingWithdrawAmount = WITHDRAW_AMOUNT;
        uint256 ongoingReturnAmount = stream.depositAmount - WITHDRAW_AMOUNT;

        vm.expectEmit(true, true, false, true);
        emit Cancel(endedStreamId, stream.recipient, endedWithdrawAmount, endedReturnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(ongoingStreamId, stream.recipient, ongoingWithdrawAmount, ongoingReturnAmount);

        uint256[] memory streamIds = createDynamicArray(endedStreamId, ongoingStreamId);
        sablierV2Cliff.cancelAll(streamIds);
    }
}
