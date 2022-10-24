// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Cancel is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotCancel__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
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
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableDaiStreamId)
        );
        sablierV2Linear.cancel(nonCancelableDaiStreamId);
    }

    modifier StreamCancelable() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancel__CallerUnauthorized() external StreamExistent StreamCancelable {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        sablierV2Linear.cancel(daiStreamId);
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should cancel and delete the stream and burn the NFT.
    function testCancel__CallerSender() external StreamExistent StreamCancelable CallerAuthorized {
        // Make the sender the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        sablierV2Linear.cancel(daiStreamId);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev it should cancel and delete the stream and burn the NFT.
    function testCancel__CallerApprovedOperator() external StreamExistent StreamCancelable CallerAuthorized {
        // Approve Alice for the stream.
        sablierV2Linear.approve(users.alice, daiStreamId);

        // Make Alice the `msg.sender` in this test case.
        changePrank(users.alice);

        // Run the test.
        sablierV2Linear.cancel(daiStreamId);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = address(0);
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
        sablierV2Linear.transferFrom(users.recipient, users.alice, daiStreamId);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.recipient)
        );
        sablierV2Linear.cancel(daiStreamId);
    }

    modifier OriginalRecipient() {
        _;
    }

    /// @dev it should cancel and delete the stream and burn the NFT.
    function testCancel__StreamEnded()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        sablierV2Linear.cancel(daiStreamId);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev it should emit a Cancel event.
    function testCancel__StreamEnded__Event()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 returnAmount = 0;
        emit Cancel(daiStreamId, users.recipient, daiStream.depositAmount, returnAmount);
        sablierV2Linear.cancel(daiStreamId);
    }

    /// @dev it should cancel and delete the stream and burn the NFT.
    function testCancel__StreamOngoing()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.cancel(daiStreamId);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev it should emit a Cancel event.
    function testCancel__StreamOngoing__Event()
        external
        StreamExistent
        StreamCancelable
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 returnAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        vm.expectEmit(true, true, false, true);
        emit Cancel(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI, returnAmount);
        sablierV2Linear.cancel(daiStreamId);
    }
}
