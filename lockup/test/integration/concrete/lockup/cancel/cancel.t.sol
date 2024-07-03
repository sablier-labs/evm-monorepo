// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupRecipient } from "src/interfaces/ISablierLockupRecipient.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
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

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.cancel(nullStreamId);
    }

    function test_RevertGiven_StatusDepleted() external whenNotDelegateCalled givenNotNull givenStreamCold {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    function test_RevertGiven_StatusCanceled() external whenNotDelegateCalled givenNotNull givenStreamCold {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamCanceled.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    function test_RevertGiven_StatusSettled() external whenNotDelegateCalled givenNotNull givenStreamCold {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamSettled.selector, defaultStreamId));
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        givenStreamWarm
        whenCallerUnauthorized
    {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.cancel(defaultStreamId);
    }

    function test_RevertWhen_CallerUnauthorized_Recipient()
        external
        whenNotDelegateCalled
        givenNotNull
        givenStreamWarm
        whenCallerUnauthorized
    {
        // Make the Recipient the caller in this test.
        resetPrank({ msgSender: users.recipient });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        lockup.cancel(defaultStreamId);
    }

    function test_RevertGiven_StreamNotCancelable()
        external
        whenNotDelegateCalled
        givenNotNull
        givenStreamWarm
        whenCallerAuthorized
    {
        uint256 streamId = createDefaultStreamNotCancelable();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCancelable.selector, streamId));
        lockup.cancel(streamId);
    }

    function test_Cancel_StatusPending() external {
        // Warp to the past.
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });

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

    function test_Cancel_RecipientNotAllowedToHook()
        external
        whenNotDelegateCalled
        givenNotNull
        givenStreamWarm
        whenCallerAuthorized
        givenStreamCancelable
        givenStatusStreaming
    {
        // Create the stream with a recipient contract that implements {ISablierLockupRecipient}.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientGood));

        // Expect Sablier to NOT run the recipient hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupCancel, (streamId, users.sender, senderAmount, recipientAmount)
            ),
            count: 0
        });

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been canceled.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_Cancel_RecipientReverting()
        external
        whenNotDelegateCalled
        givenNotNull
        givenStreamWarm
        whenCallerAuthorized
        givenStreamCancelable
        givenStatusStreaming
        givenRecipientAllowedToHook
    {
        // Allow the recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientReverting));
        resetPrank({ msgSender: users.sender });

        // Create the stream with a reverting contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientReverting));

        // Expect a revert.
        vm.expectRevert("You shall not pass");

        // Cancel the stream.
        lockup.cancel(streamId);
    }

    function test_Cancel_RecipientReturnsInvalidSelector()
        external
        whenNotDelegateCalled
        givenNotNull
        givenStreamWarm
        whenCallerAuthorized
        givenStreamCancelable
        givenStatusStreaming
        givenRecipientAllowedToHook
        whenRecipientNotReverting
    {
        // Allow the recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientInvalidSelector));
        resetPrank({ msgSender: users.sender });

        // Create the stream with a recipient contract that returns invalid selector bytes on the hook call.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientInvalidSelector));

        // Expect a revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_InvalidHookSelector.selector, address(recipientInvalidSelector)
            )
        );

        // Cancel the stream.
        lockup.cancel(streamId);
    }

    function test_Cancel_RecipientReentrant()
        external
        whenNotDelegateCalled
        givenNotNull
        givenStreamWarm
        whenCallerAuthorized
        givenStreamCancelable
        givenStatusStreaming
        givenRecipientAllowedToHook
        whenRecipientNotReverting
        whenRecipientReturnsSelector
    {
        // Allow the recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientReentrant));
        resetPrank({ msgSender: users.sender });

        // Create the stream with a reentrant contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientReentrant));

        // Expect Sablier to run the recipient hook.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(recipientReentrant),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupCancel, (streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Expect a reentrant call to the Lockup contract.
        vm.expectCall(
            address(lockup),
            abi.encodeCall(ISablierV2Lockup.withdraw, (streamId, address(recipientReentrant), recipientAmount))
        );

        // Cancel the stream.
        lockup.cancel(streamId);

        // Assert that the stream has been depleted. The reentrant recipient withdrew all the funds.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        assertEq(actualWithdrawnAmount, recipientAmount, "withdrawnAmount");
    }

    function test_Cancel()
        external
        whenNotDelegateCalled
        givenNotNull
        givenStreamWarm
        whenCallerAuthorized
        givenStreamCancelable
        givenStatusStreaming
        givenRecipientAllowedToHook
        whenRecipientNotReverting
        whenRecipientReturnsSelector
        whenRecipientNotReentrant
    {
        // Allow the recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientGood));
        resetPrank({ msgSender: users.sender });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientGood));

        // Expect the assets to be refunded to the Sender.
        uint128 senderAmount = lockup.refundableAmountOf(streamId);
        expectCallToTransfer({ to: users.sender, value: senderAmount });

        // Expect Sablier to run the recipient hook.
        uint128 recipientAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall(
            address(recipientGood),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupCancel, (streamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(streamId, users.sender, address(recipientGood), dai, senderAmount, recipientAmount);
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
        address expectedNFTOwner = address(recipientGood);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
