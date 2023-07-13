// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { ISablierV2LockupSender } from "src/interfaces/hooks/ISablierV2LockupSender.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Cancel_Integration_Shared_Test } from "../../../shared/lockup/cancel.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Cancel_Integration_Concrete_Test is Integration_Test, Cancel_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Cancel_Integration_Shared_Test) {
        Cancel_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.cancel, defaultStreamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_Null() external whenNotDelegateCalled {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.cancel(nullStreamId);
    }

    function test_RevertWhen_StreamCold_StatusDepleted() external whenNotDelegateCalled whenNotNull whenStreamCold {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_StreamCold_StatusCanceled() external whenNotDelegateCalled whenNotNull whenStreamCold {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamCanceled.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_StreamCold_StatusSettled() external whenNotDelegateCalled whenNotNull whenStreamCold {
        vm.warp({ timestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamSettled.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerUnauthorized
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_CallerUnauthorized_ApprovedOperator()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerUnauthorized
    {
        // Approve Alice for the stream.
        changePrank({ msgSender: users.recipient });
        lockup.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make Alice the caller in this test.
        changePrank({ msgSender: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.operator)
        );
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_CallerUnauthorized_FormerRecipient()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerUnauthorized
    {
        // Transfer the stream to Alice.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamId });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_StreamNotCancelable()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
    {
        uint256 streamId = createDefaultStreamNotCancelable();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCancelable.selector, streamId));
        lockup.cancel(streamId);
    }

    function test_Cancel_StatusPending() external {
        // Warp to the past.
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });

        // Cancel the stream.
        lockup.cancel(defaultStreamId);

        // Assert that the stream's status is "DEPLETED".
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    function test_Cancel_CallerSender_RecipientNotContract()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerSender
    {
        lockup.cancel(defaultStreamId);
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_CallerSender_RecipientDoesNotImplementHook()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerSender
        whenRecipientContract
    {
        // Create the stream with a no-op contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(noop));

        // Expect a call to the hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(noop),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamCanceled, (streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_CallerSender_RecipientReverts()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
    {
        // Create the stream with a reverting contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(revertingRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamCanceled, (streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_CallerSender_RecipientReentrancy()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
    {
        // Create the stream with a reentrant contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Expect a call to the hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(reentrantRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamCanceled, (streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_CallerSender()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        // Create the stream.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Expect the assets to be refunded to the Sender.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectCallToTransfer({ to: users.sender, amount: senderAmount });

        // Expect a call to the hook.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(goodRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamCanceled, (streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, users.sender, address(goodRecipient), senderAmount, recipientAmount);
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is "CANCELED".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the refunded amount has been updated.
        uint128 actualRefundedAmount = lockup.getRefundedAmount(streamId);
        uint128 expectedRefundedAmount = senderAmount;
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = address(goodRecipient);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    function test_Cancel_CallerRecipient_SenderNotContract()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerRecipient
    {
        lockup.cancel(defaultStreamId);
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_CallerRecipient_SenderDoesNotImplementHook()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerRecipient
        whenSenderContract
    {
        // Create a stream with a no-op contract as the stream's sender.
        uint256 streamId = createDefaultStreamWithSender(address(noop));

        // Expect a call to the hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(noop),
            abi.encodeCall(
                ISablierV2LockupSender.onStreamCanceled, (streamId, users.recipient, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is "CANCELED".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_CallerRecipient_SenderReverts()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
    {
        // Create a stream with a reverting contract as the stream's sender.
        uint256 streamId = createDefaultStreamWithSender(address(revertingSender));

        // Expect a call to the hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(revertingSender),
            abi.encodeCall(
                ISablierV2LockupSender.onStreamCanceled, (streamId, users.recipient, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is "CANCELED".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_CallerRecipient_SenderReentrancy()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
        whenSenderDoesNotRevert
    {
        // Create a stream with a reentrant contract as the stream's sender.
        uint256 streamId = createDefaultStreamWithSender(address(reentrantSender));

        // Expect a call to the hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(reentrantSender),
            abi.encodeCall(
                ISablierV2LockupSender.onStreamCanceled, (streamId, users.recipient, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is "CANCELED".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_CallerRecipient()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
        whenSenderDoesNotRevert
        whenNoSenderReentrancy
    {
        // Create the stream.
        uint256 streamId = createDefaultStreamWithSender(address(goodSender));

        // Expect the assets to be refunded to the sender contract.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectCallToTransfer({ to: address(goodSender), amount: senderAmount });

        // Expect a call to the hook.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(goodSender),
            abi.encodeCall(
                ISablierV2LockupSender.onStreamCanceled, (streamId, users.recipient, senderAmount, recipientAmount)
            )
        );

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, address(goodSender), users.recipient, senderAmount, recipientAmount);
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is "CANCELED".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the refunded amount has been updated.
        uint128 actualRefundedAmount = lockup.getRefundedAmount(streamId);
        uint128 expectedRefundedAmount = senderAmount;
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
