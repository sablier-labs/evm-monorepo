// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";
import { Errors } from "@sablier/v2-core/libraries/Errors.sol";
import { Events } from "@sablier/v2-core/libraries/Events.sol";

import { SablierV2LinearBaseTest } from "../SablierV2LinearBaseTest.t.sol";

contract CancelAll__Tests is SablierV2LinearBaseTest {
    uint256[] internal defaultStreamIds;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultDaiStream());
        defaultStreamIds.push(createDefaultDaiStream());

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should do nothing.
    function testCannotCancelAll__OnlyNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId);
        sablierV2Linear.cancelAll(streamIds);
    }

    /// @dev it should cancel and delete the existent streams and burn the NFTs.
    function testCannotCancelAll__SomeNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonStreamId);
        sablierV2Linear.cancelAll(streamIds);
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(defaultStreamIds[0]);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier OnlyExistentStreams() {
        _;
    }

    /// @dev it should do nothing.
    function testCannotCancelAll__AllStreamsNonCancelable() external OnlyExistentStreams {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        uint256[] memory nonCancelableStreamIds = createDynamicArray(nonCancelableDaiStreamId);
        sablierV2Linear.cancelAll(nonCancelableStreamIds);
    }

    /// @dev it should cancel and delete the cancelable streams and burn the NFTs.
    function testCannotCancelAll__SomeStreamsNonCancelable() external OnlyExistentStreams {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], nonCancelableDaiStreamId);
        sablierV2Linear.cancelAll(streamIds);
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(defaultStreamIds[0]);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier AllStreamsCancelable() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedAllStreams() external OnlyExistentStreams AllStreamsCancelable {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelAll__CallerUnauthorizedSomeStreams() external OnlyExistentStreams AllStreamsCancelable {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Create a stream with Eve as the sender.
        uint256 eveStreamId = sablierV2Linear.create(
            users.eve,
            users.recipient,
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
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.cancelAll(streamIds);
    }

    modifier CallerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should cancel and delete the streams and burn the NFTs.
    function testCancelAll__CallerSenderAllStreams()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
    {
        // Make the sender the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        sablierV2Linear.cancelAll(defaultStreamIds);

        DataTypes.LinearStream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        address actualRecipient0 = sablierV2Linear.getRecipient(defaultStreamIds[0]);
        address actualRecipient1 = sablierV2Linear.getRecipient(defaultStreamIds[1]);
        address expectedRecipient = address(0);
        assertEq(actualRecipient0, expectedRecipient);
        assertEq(actualRecipient1, expectedRecipient);
    }

    /// @dev it should cancel and delete the streams and burn the NFTs.
    function testCancelAll__CallerApprovedOperatorAllStreams()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
    {
        // Approve the operator for all streams.
        sablierV2Linear.setApprovalForAll(users.operator, true);

        // Make the operator the `msg.sender` in this test case.
        changePrank(users.operator);

        // Run the test.
        sablierV2Linear.cancelAll(defaultStreamIds);

        DataTypes.LinearStream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        address actualRecipient0 = sablierV2Linear.getRecipient(defaultStreamIds[0]);
        address actualRecipient1 = sablierV2Linear.getRecipient(defaultStreamIds[1]);
        address expectedRecipient = address(0);
        assertEq(actualRecipient0, expectedRecipient);
        assertEq(actualRecipient1, expectedRecipient);
    }

    modifier CallerRecipientAllStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancelAll__OriginalRecipientTransferredOwnershipAllStreams()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
    {
        // Transfer the streams to Alice.
        sablierV2Linear.transferFrom(users.recipient, users.alice, defaultStreamIds[0]);
        sablierV2Linear.transferFrom(users.recipient, users.alice, defaultStreamIds[1]);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2Linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should revert.
    function testCannotCancelAll__OriginalRecipientTransferredOnwershipSomeStreams()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
    {
        // Transfer one of the streams to eve.
        sablierV2Linear.transferFrom(users.recipient, users.alice, defaultStreamIds[0]);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2Linear.cancelAll(defaultStreamIds);
    }

    modifier OriginalRecipientAllStreams() {
        _;
    }

    /// @dev it should cancel and delete the streams and burn the NFTs.
    function testCancelAll__AllStreamsEnded()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        sablierV2Linear.cancelAll(defaultStreamIds);

        DataTypes.LinearStream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        address actualRecipient0 = sablierV2Linear.getRecipient(defaultStreamIds[0]);
        address actualRecipient1 = sablierV2Linear.getRecipient(defaultStreamIds[1]);
        address expectedRecipient = address(0);
        assertEq(actualRecipient0, expectedRecipient);
        assertEq(actualRecipient1, expectedRecipient);
    }

    /// @dev it should emit multiple Cancel events.
    function testCancelAll__AllStreamsEnded__Events()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        uint256 returnAmount = 0;

        vm.expectEmit(true, true, false, true);
        emit Events.Cancel(defaultStreamIds[0], users.recipient, daiStream.depositAmount, returnAmount);
        vm.expectEmit(true, true, false, true);
        emit Events.Cancel(defaultStreamIds[1], users.recipient, daiStream.depositAmount, returnAmount);

        uint256[] memory streamIds = createDynamicArray(defaultStreamIds[0], defaultStreamIds[1]);
        sablierV2Linear.cancelAll(streamIds);
    }

    /// @dev it should cancel and delete the streams and burn the NFTs.
    function testCancelAll__AllStreamsOngoing()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.cancelAll(defaultStreamIds);

        DataTypes.LinearStream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        address actualRecipient0 = sablierV2Linear.getRecipient(defaultStreamIds[0]);
        address actualRecipient1 = sablierV2Linear.getRecipient(defaultStreamIds[1]);
        address expectedRecipient = address(0);
        assertEq(actualRecipient0, expectedRecipient);
        assertEq(actualRecipient1, expectedRecipient);
    }

    /// @dev it should emit multiple Cancel events.
    function testCancelAll__AllStreamsOngoing__Events()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 returnAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;

        vm.expectEmit(true, true, false, true);
        emit Events.Cancel(defaultStreamIds[0], users.recipient, WITHDRAW_AMOUNT_DAI, returnAmount);
        vm.expectEmit(true, true, false, true);
        emit Events.Cancel(defaultStreamIds[1], users.recipient, WITHDRAW_AMOUNT_DAI, returnAmount);

        sablierV2Linear.cancelAll(defaultStreamIds);
    }

    /// @dev it should cancel and delete the streams and burn the NFTs.
    function testCancelAll__SomeStreamsEndedSomeStreamsOngoing()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
    {
        // Use the first default stream as the ongoing DAI stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended dai stream.
        uint64 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
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

        DataTypes.LinearStream memory deletedOngoingStream = sablierV2Linear.getStream(ongoingStreamId);
        DataTypes.LinearStream memory deletedEndedStream = sablierV2Linear.getStream(endedDaiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedOngoingStream, expectedStream);
        assertEq(deletedEndedStream, expectedStream);

        address actualRecipient0 = sablierV2Linear.getRecipient(ongoingStreamId);
        address actualRecipient1 = sablierV2Linear.getRecipient(endedDaiStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient0, expectedRecipient);
        assertEq(actualRecipient1, expectedRecipient);
    }

    /// @dev it should emit multiple Cancel events.
    function testCancelAll__SomeStreamsEndedSomeStreamsOngoing__Events()
        external
        OnlyExistentStreams
        AllStreamsCancelable
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
    {
        // Use the first default stream as the ongoing DAI stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended dai stream.
        uint64 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
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
        emit Events.Cancel(endedDaiStreamId, users.recipient, endedWithdrawAmount, endedReturnAmount);
        vm.expectEmit(true, true, false, true);
        emit Events.Cancel(ongoingStreamId, users.recipient, ongoingWithdrawAmount, ongoingReturnAmount);

        uint256[] memory streamIds = createDynamicArray(endedDaiStreamId, ongoingStreamId);
        sablierV2Linear.cancelAll(streamIds);
    }
}
