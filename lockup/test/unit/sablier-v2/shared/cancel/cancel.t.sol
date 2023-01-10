// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract Cancel_Test is SharedTest {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        super.setUp();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_StreamNonExistent.selector, nonStreamId));
        sablierV2.cancel(nonStreamId);
    }

    modifier streamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNonCancelable() external streamExistent {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_StreamNonCancelable.selector, streamId));
        sablierV2.cancel(streamId);
    }

    modifier streamCancelable() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorized_MaliciousThirdParty(
        address eve
    ) external streamExistent streamCancelable {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Make the unauthorized user the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamId, eve));
        sablierV2.cancel(defaultStreamId);
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorized_ApprovedOperator(
        address operator
    ) external streamExistent streamCancelable {
        vm.assume(operator != address(0) && operator != users.sender && operator != users.recipient);

        // Approve Alice for the stream.
        sablierV2.approve({ to: operator, tokenId: defaultStreamId });

        // Make Alice the caller in this test.
        changePrank(operator);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamId, operator));
        sablierV2.cancel(defaultStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_FormerRecipient() external streamExistent streamCancelable {
        // Transfer the stream to Alice.
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamId });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        sablierV2.cancel(defaultStreamId);
    }

    modifier callerAuthorized() {
        _;
    }

    modifier callerSender() {
        // Make the sender the caller in this test suite.
        changePrank(users.sender);
        _;
    }

    /// @dev it should cancel the stream.
    function test_Cancel_Sender_RecipientNotContract()
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerSender
    {
        sablierV2.cancel(defaultStreamId);
        assertDeleted(defaultStreamId);
    }

    modifier recipientContract() {
        _;
    }

    /// @dev it should cancel the stream.
    function testCancel_Sender_RecipientDoesNotImplementHook()
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerSender
        recipientContract
    {
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));
        sablierV2.cancel(streamId);
        assertDeleted(streamId);
    }

    modifier recipientImplementsHook() {
        _;
    }

    /// @dev it should ignore the revert and cancel the stream.
    function testCancel_Sender_RecipientReverts()
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerSender
        recipientContract
        recipientImplementsHook
    {
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));
        sablierV2.cancel(streamId);
        assertDeleted(streamId);
    }

    modifier recipientDoesNotRevert() {
        _;
    }

    /// @dev it should ignore the revert and cancel the stream.
    function testCancel_Sender_RecipientReentrancy()
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerSender
        recipientContract
        recipientImplementsHook
        recipientDoesNotRevert
    {
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));
        sablierV2.cancel(streamId);
        assertDeleted(streamId);
    }

    modifier noRecipientReentrancy() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit a Cancel event, and cancel the stream.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Stream ongoing.
    /// - Stream ended.
    function testFuzz_Cancel_Sender(
        uint256 timeWarp
    )
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerSender
        recipientContract
        recipientImplementsHook
        recipientDoesNotRevert
        noRecipientReentrancy
    {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Create the stream.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Expect the tokens to be withdrawn to the recipient.
        uint128 recipientAmount = sablierV2.getWithdrawableAmount(streamId);
        if (recipientAmount > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (address(goodRecipient), recipientAmount)));
        }

        // Expect the tokens to be returned to the sender.
        uint128 senderAmount = DEFAULT_NET_DEPOSIT_AMOUNT - recipientAmount;
        if (senderAmount > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, senderAmount)));
        }

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamId, users.sender, address(goodRecipient), senderAmount, recipientAmount);

        // Cancel the stream.
        sablierV2.cancel(streamId);

        // Assert that the stream was deleted.
        assertDeleted(streamId);

        // Assert that the NFT was not burned.
        address actualNFTOwner = sablierV2.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = address(goodRecipient);
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    modifier callerRecipient() {
        _;
    }

    /// @dev it should cancel the stream.
    function testCancel_Recipient_SenderNotContract()
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerRecipient
    {
        sablierV2.cancel(defaultStreamId);
        assertDeleted(defaultStreamId);
    }

    modifier senderContract() {
        _;
    }

    /// @dev it should cancel the stream.
    function testCancel_Recipient_SenderDoesNotImplementHook()
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerRecipient
        senderContract
    {
        uint256 streamId = createDefaultStreamWithSender(address(empty));
        sablierV2.cancel(streamId);
        assertDeleted(streamId);
    }

    modifier senderImplementsHook() {
        _;
    }

    /// @dev it should cancel the stream.
    function testCancel_Recipient_SenderReverts()
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerRecipient
        senderContract
        senderImplementsHook
    {
        uint256 streamId = createDefaultStreamWithSender(address(revertingSender));
        sablierV2.cancel(streamId);

        // Assert that the stream was deleted.
        assertDeleted(streamId);
    }

    modifier senderDoesNotRevert() {
        _;
    }

    /// @dev it should ignore the revert and make the withdrawal and cancel the stream.
    function testCancel_Recipient_SenderReentrancy()
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerRecipient
        senderContract
        senderImplementsHook
        senderDoesNotRevert
    {
        uint256 streamId = createDefaultStreamWithSender(address(reentrantSender));
        sablierV2.cancel(streamId);

        // Assert that the stream was deleted.
        assertDeleted(streamId);
    }

    modifier noSenderReentrancy() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, emit a Cancel event, and cancel the stream.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Stream ongoing.
    /// - Stream ended.
    function testFuzz_Cancel_Recipient(
        uint256 timeWarp
    )
        external
        streamExistent
        streamCancelable
        callerAuthorized
        callerRecipient
        senderContract
        senderImplementsHook
        senderDoesNotRevert
        noSenderReentrancy
    {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithSender(address(goodSender));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Expect the tokens to be withdrawn to the recipient, if not zero.
        uint128 recipientAmount = sablierV2.getWithdrawableAmount(streamId);
        if (recipientAmount > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, recipientAmount)));
        }

        // Expect the tokens to be returned to the sender, if not zero.
        uint128 senderAmount = DEFAULT_NET_DEPOSIT_AMOUNT - recipientAmount;
        if (senderAmount > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (address(goodSender), senderAmount)));
        }

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamId, address(goodSender), users.recipient, senderAmount, recipientAmount);

        // Cancel the stream.
        sablierV2.cancel(streamId);

        // Assert that the stream was deleted.
        assertDeleted(streamId);

        // Assert that the NFT was not burned.
        address actualNFTOwner = sablierV2.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }
}
