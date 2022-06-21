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
        defaultStreamIds.push(createDefaultDaiStream());
        defaultStreamIds.push(createDefaultDaiStream());
    }

    /// @dev When the stream ids array points only to non existent streams, it should do nothing.
    function testCannotCancelAll__OnlyNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId);
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When the stream ids array points to some non existent streams, it should cancel and delete
    /// the non existent streams.
    function testCannotCancelAll__SomeNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonStreamId);
        sablierV2Cliff.cancelAll(streamIds);
        ISablierV2Cliff.Stream memory actualStream = sablierV2Cliff.getStream(defaultStreamIds[0]);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
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
        uint256 eveStreamId = sablierV2Cliff.create(
            users.eve,
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
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When the caller is the recipient of all streams, it should cancel and delete the streams.
    function testCancelAll__CallerRecipient__AllStreams() external {
        // Make the recipient the `msg.sender` in this test case.
        changePrank(users.recipient);

        // Run the test.
        sablierV2Cliff.cancelAll(defaultStreamIds);

        ISablierV2Cliff.Stream memory actualStream0 = sablierV2Cliff.getStream(defaultStreamIds[0]);
        ISablierV2Cliff.Stream memory actualStream1 = sablierV2Cliff.getStream(defaultStreamIds[1]);
        ISablierV2Cliff.Stream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);
    }

    /// @dev When all streams are non-cancelable, it should do nothing.
    function testCannotCancelAll__AllStreamsNonCancelable() external {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        uint256[] memory nonCancelableStreamIds = createDynamicArray(nonCancelableDaiStreamId);
        sablierV2Cliff.cancelAll(nonCancelableStreamIds);
    }

    /// @dev When some streams are non-cancelable, it should cancel and delete the cancelable streams.
    function testCannotCancelAll__SomeStreamsNonCancelable() external {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonCancelableDaiStreamId);
        sablierV2Cliff.cancelAll(streamIds);
        ISablierV2Cliff.Stream memory actualStream = sablierV2Cliff.getStream(defaultStreamIds[0]);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev When all streams are ended, it should cancel and delete the streams.
    function testCancelAll__AllStreamsEnded() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

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
        vm.warp(daiStream.stopTime);

        // Run the test.
        uint256 withdrawAmount = daiStream.depositAmount;
        uint256 returnAmount = 0;

        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[0], daiStream.recipient, withdrawAmount, returnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[1], daiStream.recipient, withdrawAmount, returnAmount);

        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], defaultStreamIds[1]);
        sablierV2Cliff.cancelAll(streamIds);
    }

    /// @dev When all streams are ongoing, it should cancel and delete the streams.
    function testCancelAll__AllStreamsOngoing() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

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
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        uint256 returnAmount = daiStream.depositAmount - WITHDRAW_AMOUNT;

        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[0], daiStream.recipient, withdrawAmount, returnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(defaultStreamIds[1], daiStream.recipient, withdrawAmount, returnAmount);

        sablierV2Cliff.cancelAll(defaultStreamIds);
    }

    /// @dev When some of the streams are ended and some are ongoing, it should cancel and delete the streams.
    function testCancelAll__SomeStreamsEndedSomeStreamsOngoing() external {
        // Use the first default stream as the ongoing daiStream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended daiStream.
        uint256 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedStreamId = sablierV2Cliff.create(
            daiStream.sender,
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
        // Use the first default stream as the ongoing daiStream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended daiStream.
        uint256 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedStreamId = sablierV2Cliff.create(
            daiStream.sender,
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
        uint256 ongoingWithdrawAmount = WITHDRAW_AMOUNT;
        uint256 ongoingReturnAmount = daiStream.depositAmount - WITHDRAW_AMOUNT;

        vm.expectEmit(true, true, false, true);
        emit Cancel(endedStreamId, daiStream.recipient, endedWithdrawAmount, endedReturnAmount);
        vm.expectEmit(true, true, false, true);
        emit Cancel(ongoingStreamId, daiStream.recipient, ongoingWithdrawAmount, ongoingReturnAmount);

        uint256[] memory streamIds = createDynamicArray(endedStreamId, ongoingStreamId);
        sablierV2Cliff.cancelAll(streamIds);
    }
}
