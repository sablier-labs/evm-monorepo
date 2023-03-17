// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { ISablierV2LockupSender } from "src/interfaces/hooks/ISablierV2LockupSender.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract Cancel_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCall() external whenNoDelegateCall whenStreamActive {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.cancel, defaultStreamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenStreamNotActive() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external whenNoDelegateCall whenStreamNotActive {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, nullStreamId));
        lockup.cancel(nullStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamCanceled() external whenNoDelegateCall whenStreamNotActive {
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamDepleted() external whenNoDelegateCall whenStreamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    modifier whenStreamActive() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNonCancelable() external whenNoDelegateCall whenStreamActive {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNonCancelable.selector, streamId));
        lockup.cancel(streamId);
    }

    modifier whenStreamCancelable() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenNoDelegateCall
    {
        // Make the unauthorized user the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.cancel(defaultStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_ApprovedOperator()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenNoDelegateCall
    {
        // Approve Alice for the stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make Alice the caller in this test.
        changePrank(users.operator);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.operator)
        );
        lockup.cancel(defaultStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_FormerRecipient()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
    {
        // Transfer the stream to Alice.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamId });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        lockup.cancel(defaultStreamId);
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier whenCallerSender() {
        // Make the sender the caller in this test suite.
        changePrank({ msgSender: users.sender });
        _;
    }

    /// @dev it should cancel the stream.
    function test_Cancel_Sender_RecipientNotContract()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenNoDelegateCall
        whenCallerAuthorized
        whenCallerSender
    {
        lockup.cancel(defaultStreamId);
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenRecipientContract() {
        _;
    }

    /// @dev it should cancel the stream, call the recipient hook, and ignore the revert.
    function test_Cancel_Sender_RecipientDoesNotImplementHook()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerSender
        whenRecipientContract
    {
        // Create the stream with an empty contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Expect a call to the recipient hook.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(empty),
            abi.encodeCall(ISablierV2LockupRecipient.onStreamCanceled, (streamId, senderAmount, recipientAmount))
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    /// @dev it should cancel the stream, call the recipient hook, and ignore the revert.
    function test_Cancel_Sender_RecipientReverts()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
    {
        // Create the stream with a reverting contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the recipient hook.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(revertingRecipient),
            abi.encodeCall(ISablierV2LockupRecipient.onStreamCanceled, (streamId, senderAmount, recipientAmount))
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    /// @dev it should cancel the stream, call the recipient hook, and ignore the revert.
    function test_Cancel_Sender_RecipientReentrancy()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
    {
        // Create the stream with a reentrant contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Expect a call to the recipient hook.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(reentrantRecipient),
            abi.encodeCall(ISablierV2LockupRecipient.onStreamCanceled, (streamId, senderAmount, recipientAmount))
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, cancel the stream, update the withdrawn amount, call the
    /// recipient hook, and emit a {CancelLockupStream} event.
    function test_Cancel_Sender()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Expect the ERC-20 assets to be returned to the sender, if not zero.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        expectTransferCall({ to: users.sender, amount: senderAmount });

        // Expect the ERC-20 assets to be withdrawn to the recipient, if not zero.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        expectTransferCall({ to: address(goodRecipient), amount: recipientAmount });

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(goodRecipient),
            abi.encodeCall(ISablierV2LockupRecipient.onStreamCanceled, (streamId, senderAmount, recipientAmount))
        );

        // Expect a {CancelLockupStream} event to be emitted.
        vm.expectEmit();
        emit CancelLockupStream(streamId, users.sender, address(goodRecipient), senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been marked as canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = recipientAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = address(goodRecipient);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    modifier whenCallerRecipient() {
        _;
    }

    /// @dev it should cancel the stream.
    function test_Cancel_Recipient_SenderNotContract()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerRecipient
    {
        lockup.cancel(defaultStreamId);
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenSenderContract() {
        _;
    }

    /// @dev it should cancel the stream, call the sender hook, and ignore the revert.
    function test_Cancel_Recipient_SenderDoesNotImplementHook()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerRecipient
        whenSenderContract
    {
        // Create a stream with an empty contract as the sender.
        uint256 streamId = createDefaultStreamWithSender(address(empty));

        // Expect a call to the sender hook.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(empty),
            abi.encodeCall(ISablierV2LockupSender.onStreamCanceled, (streamId, senderAmount, recipientAmount))
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been marked as canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenSenderImplementsHook() {
        _;
    }

    /// @dev it should cancel the stream, call the sender hook, and ignore the revert.
    function test_Cancel_Recipient_SenderReverts()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
    {
        // Create a stream with a reverting contract as the sender.
        uint256 streamId = createDefaultStreamWithSender(address(revertingSender));

        // Expect a call to the sender hook.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(revertingSender),
            abi.encodeCall(ISablierV2LockupSender.onStreamCanceled, (streamId, senderAmount, recipientAmount))
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been marked as canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenSenderDoesNotRevert() {
        _;
    }

    /// @dev it should cancel the stream, call the sender hook, and ignore the revert.
    function test_Cancel_Recipient_SenderReentrancy()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
        whenSenderDoesNotRevert
    {
        // Create a stream with a reentrant contract as the sender.
        uint256 streamId = createDefaultStreamWithSender(address(reentrantSender));

        // Expect a call to the sender hook.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(reentrantSender),
            abi.encodeCall(ISablierV2LockupSender.onStreamCanceled, (streamId, senderAmount, recipientAmount))
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been marked as canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenNoSenderReentrancy() {
        _;
    }

    /// @dev it should cancel the stream, update the withdrawn amount, perform the ERC-20 transfers, call the
    /// sender hook, and emit a {CancelLockupStream} event
    function test_Cancel_Recipient()
        external
        whenNoDelegateCall
        whenStreamActive
        whenStreamCancelable
        whenCallerAuthorized
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
        whenSenderDoesNotRevert
        whenNoSenderReentrancy
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithSender(address(goodSender));

        // Expect the ERC-20 assets to be returned to the sender.
        uint128 senderAmount = lockup.returnableAmountOf(streamId);
        expectTransferCall({ to: address(goodSender), amount: senderAmount });

        // Expect the ERC-20 assets to be withdrawn to the recipient.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        expectTransferCall({ to: users.recipient, amount: recipientAmount });

        // Expect a call to the sender hook.
        vm.expectCall(
            address(goodSender),
            abi.encodeCall(ISablierV2LockupSender.onStreamCanceled, (streamId, senderAmount, recipientAmount))
        );

        // Expect a {CancelLockupStream} event to be emitted.
        vm.expectEmit();
        emit CancelLockupStream(streamId, address(goodSender), users.recipient, senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been marked as canceled.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = recipientAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
