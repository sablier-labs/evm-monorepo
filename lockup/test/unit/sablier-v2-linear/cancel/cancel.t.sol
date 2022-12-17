// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract Cancel__Test is SablierV2LinearTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotCancel__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Linear.cancel(nonStreamId);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancel__StreamNonCancelable() external StreamExistent {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__StreamNonCancelable.selector, nonCancelableDaiStreamId)
        );
        sablierV2Linear.cancel(nonCancelableDaiStreamId);
    }

    modifier StreamCancelable() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancel__CallerMaliciousThirdParty() external StreamExistent StreamCancelable {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        sablierV2Linear.cancel(daiStreamId);
    }

    /// @dev it should revert.
    function testCannotCancel__CallerApprovedOperator() external StreamExistent StreamCancelable {
        // Approve Alice for the stream.
        sablierV2Linear.approve({ to: users.operator, tokenId: daiStreamId });

        // Make Alice the caller in this test.
        changePrank(users.operator);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.operator));
        sablierV2Linear.cancel(daiStreamId);
    }

    modifier CallerAuthorized() {
        _;
    }

    modifier CallerSender() {
        // Make the sender the caller in this test suite.
        changePrank(users.sender);
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__RecipientNotContract() external StreamExistent StreamCancelable CallerAuthorized CallerSender {
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier RecipientContract() {
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__RecipientDoesNotImplementHook()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerSender
        RecipientContract
    {
        daiStreamId = createDefaultDaiStreamWithRecipient(address(empty));
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = address(empty);
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__RecipientImplementsHook()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerSender
        RecipientContract
    {
        daiStreamId = createDefaultDaiStreamWithRecipient(address(nonRevertingRecipient));
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = address(nonRevertingRecipient);
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier CallerRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancel__OriginalRecipientTransferredOwnership()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
    {
        // Transfer the stream to Alice.
        sablierV2Linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: daiStreamId });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.recipient));
        sablierV2Linear.cancel(daiStreamId);
    }

    modifier OriginalRecipient() {
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__StreamEnded()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: daiStream.stopTime });

        // Run the test.
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier StreamOngoing() {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__SenderNotContract()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        StreamOngoing
    {
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier SenderContract() {
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__SenderDoesNotImplementHook()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        StreamOngoing
        SenderContract
    {
        daiStreamId = createDefaultDaiStreamWithSender(address(empty));
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier SenderImplementsHook() {
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__SenderReverts()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        StreamOngoing
        SenderContract
        SenderImplementsHook
    {
        daiStreamId = createDefaultDaiStreamWithSender(address(revertingSender));
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier SenderDoesNotRevert() {
        _;
    }

    /// @dev it should ignore the revert and make the withdrawal and delete the stream.
    function testCannotCancel__Reentrancy()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        StreamOngoing
        SenderContract
        SenderImplementsHook
        SenderDoesNotRevert
    {
        daiStreamId = createDefaultDaiStreamWithSender(address(reentrantSender));
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier NoReentrancy() {
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        StreamOngoing
        SenderContract
        SenderImplementsHook
        SenderDoesNotRevert
        NoReentrancy
    {
        daiStreamId = createDefaultDaiStreamWithSender(address(nonRevertingSender));
        sablierV2Linear.cancel(daiStreamId);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev it should emit a Cancel event.
    function testCancel__Event()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        StreamOngoing
        SenderContract
        SenderImplementsHook
        SenderDoesNotRevert
        NoReentrancy
    {
        daiStreamId = createDefaultDaiStreamWithSender(address(nonRevertingSender));
        uint128 returnAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel({
            streamId: daiStreamId,
            sender: address(nonRevertingSender),
            recipient: users.recipient,
            withdrawAmount: WITHDRAW_AMOUNT_DAI,
            returnAmount: returnAmount
        });
        sablierV2Linear.cancel(daiStreamId);
    }
}
