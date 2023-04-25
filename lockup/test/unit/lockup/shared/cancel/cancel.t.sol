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
        defaultStreamId = createDefaultStream();
        changePrank({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.cancel, defaultStreamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_RevertWhen_Null() external whenNoDelegateCall {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.cancel(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    modifier whenStreamNotWarm() {
        _;
    }

    function test_RevertWhen_StreamNotWarm_StatusSettled() external whenNoDelegateCall whenNotNull whenStreamNotWarm {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotWarm.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_StreamNotWarm_StatusCanceled() external whenNoDelegateCall whenNotNull whenStreamNotWarm {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotWarm.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_StreamNotWarm_StatusDepleted() external whenNoDelegateCall whenNotNull whenStreamNotWarm {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotWarm.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    modifier whenStreamWarm() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty()
        external
        whenNoDelegateCall
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
        whenNoDelegateCall
        whenNotNull
        whenStreamWarm
        whenCallerUnauthorized
    {
        // Approve Alice for the stream.
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
        whenNoDelegateCall
        whenNotNull
        whenStreamWarm
        whenCallerUnauthorized
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

    function test_RevertWhen_StreamNotCancelable()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
    {
        uint256 streamId = createDefaultStreamNotCancelable();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCancelable.selector, streamId));
        lockup.cancel(streamId);
    }

    modifier whenStreamCancelable() {
        _;
    }

    function test_Cancel_StatusPending() external {
        // Warp into the past.
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });

        // Cancel the stream.
        lockup.cancel(defaultStreamId);

        // Assert that the stream's status is depleted.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    /// @dev In the linear contract, the streaming starts after the cliff time, whereas in the dynamic contract,
    /// the streaming starts after the start time.
    modifier whenStatusStreaming() {
        // Warp into the future, after the start time but before the end time.
        vm.warp({ timestamp: WARP_26_PERCENT });
        _;
    }

    modifier whenCallerSender() {
        changePrank({ msgSender: users.sender });
        _;
    }

    function test_Cancel_CallerSender_RecipientNotContract()
        external
        whenNoDelegateCall
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

    modifier whenRecipientContract() {
        _;
    }

    function test_Cancel_CallerSender_RecipientDoesNotImplementHook()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerSender
        whenRecipientContract
    {
        // Create the stream with an empty contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Expect a call to the recipient hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(empty),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamCanceled,
                (lockup, streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    function test_Cancel_CallerSender_RecipientReverts()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerSender
        whenRecipientContract
        whenRecipientImplementsHook
    {
        // Create the stream with a reverting contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the recipient hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(revertingRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamCanceled,
                (lockup, streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    function test_Cancel_CallerSender_RecipientReentrancy()
        external
        whenNoDelegateCall
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

        // Expect a call to the recipient hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(reentrantRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamCanceled,
                (lockup, streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    function test_Cancel_CallerSender()
        external
        whenNoDelegateCall
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

        // Expect the assets to be refunded to the sender.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectTransferCall({ to: users.sender, amount: senderAmount });

        // Expect a call to the recipient hook.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(goodRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamCanceled,
                (lockup, streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Expect a {CancelLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, users.sender, address(goodRecipient), senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the refunded amount has been updated.
        uint128 actualReturnedAmount = lockup.getRefundedAmount(streamId);
        uint128 expectedReturnedAmount = senderAmount;
        assertEq(actualReturnedAmount, expectedReturnedAmount, "refundedAmount");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = address(goodRecipient);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    modifier whenCallerRecipient() {
        _;
    }

    function test_Cancel_CallerRecipient_SenderNotContract()
        external
        whenNoDelegateCall
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

    modifier whenSenderContract() {
        _;
    }

    function test_Cancel_CallerRecipient_SenderDoesNotImplementHook()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerRecipient
        whenSenderContract
    {
        // Create a stream with an empty contract as the sender.
        uint256 streamId = createDefaultStreamWithSender(address(empty));

        // Expect a call to the sender hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(empty),
            abi.encodeCall(
                ISablierV2LockupSender.onStreamCanceled,
                (lockup, streamId, users.recipient, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenSenderImplementsHook() {
        _;
    }

    function test_Cancel_CallerRecipient_SenderReverts()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamWarm
        whenCallerAuthorized
        whenStreamCancelable
        whenStatusStreaming
        whenCallerRecipient
        whenSenderContract
        whenSenderImplementsHook
    {
        // Create a stream with a reverting contract as the sender.
        uint256 streamId = createDefaultStreamWithSender(address(revertingSender));

        // Expect a call to the sender hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(revertingSender),
            abi.encodeCall(
                ISablierV2LockupSender.onStreamCanceled,
                (lockup, streamId, users.recipient, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenSenderDoesNotRevert() {
        _;
    }

    function test_Cancel_CallerRecipient_SenderReentrancy()
        external
        whenNoDelegateCall
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
        // Create a stream with a reentrant contract as the sender.
        uint256 streamId = createDefaultStreamWithSender(address(reentrantSender));

        // Expect a call to the sender hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(reentrantSender),
            abi.encodeCall(
                ISablierV2LockupSender.onStreamCanceled,
                (lockup, streamId, users.recipient, senderAmount, recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenNoSenderReentrancy() {
        _;
    }

    function test_Cancel_CallerRecipient()
        external
        whenNoDelegateCall
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

        // Expect the assets to be refunded to the sender.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectTransferCall({ to: address(goodSender), amount: senderAmount });

        // Expect a call to the sender hook.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(goodSender),
            abi.encodeCall(
                ISablierV2LockupSender.onStreamCanceled,
                (lockup, streamId, users.recipient, senderAmount, recipientAmount)
            )
        );

        // Expect a {CancelLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, address(goodSender), users.recipient, senderAmount, recipientAmount);

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream's status is canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the refunded amount has been updated.
        uint128 actualReturnedAmount = lockup.getRefundedAmount(streamId);
        uint128 expectedReturnedAmount = senderAmount;
        assertEq(actualReturnedAmount, expectedReturnedAmount, "refundedAmount");

        // Assert that the NFT has not been burned.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
