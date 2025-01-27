// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { ISablierLockupRecipient } from "src/interfaces/ISablierLockupRecipient.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Cancel_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({ callData: abi.encodeCall(lockup.cancel, defaultStreamId) });
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        expectRevert_Null({ callData: abi.encodeCall(lockup.cancel, nullStreamId) });
    }

    function test_RevertGiven_DEPLETEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        expectRevert_DEPLETEDStatus({ callData: abi.encodeCall(lockup.cancel, defaultStreamId) });
    }

    function test_RevertGiven_CANCELEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        expectRevert_CANCELEDStatus({ callData: abi.encodeCall(lockup.cancel, defaultStreamId) });
    }

    function test_RevertGiven_SETTLEDStatus() external whenNoDelegateCall givenNotNull givenColdStream {
        expectRevert_SETTLEDStatus({ callData: abi.encodeCall(lockup.cancel, defaultStreamId) });
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerNotSender
    {
        expectRevert_CallerMaliciousThirdParty({ callData: abi.encodeCall(lockup.cancel, defaultStreamId) });
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerNotSender
    {
        // Make the Recipient the caller in this test.
        resetPrank({ msgSender: users.recipient });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        lockup.cancel(defaultStreamId);
    }

    function test_RevertGiven_NonCancelableStream()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerSender
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_StreamNotCancelable.selector, notCancelableStreamId)
        );
        lockup.cancel(notCancelableStreamId);
    }

    function test_GivenPENDINGStatus()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerSender
        givenCancelableStream
    {
        // Warp to the past.
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });

        // Cancel the stream.
        lockup.cancel(defaultStreamId);

        // It should mark the stream as depleted.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // It should make the stream not cancelable.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    function test_GivenRecipientNotAllowedToHook()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerSender
        givenCancelableStream
        givenSTREAMINGStatus
    {
        // It should not make Sablier run the recipient hook.
        uint128 senderAmount = lockup.refundableAmountOf(notAllowedtoHookStreamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(notAllowedtoHookStreamId);
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupCancel,
                (notAllowedtoHookStreamId, users.sender, senderAmount, recipientAmount)
            ),
            count: 0
        });

        // Cancel the stream.
        lockup.cancel(notAllowedtoHookStreamId);

        // It should mark the stream as canceled.
        Lockup.Status actualStatus = lockup.statusOf(notAllowedtoHookStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_WhenRevertingRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerSender
        givenCancelableStream
        givenSTREAMINGStatus
        givenRecipientAllowedToHook
    {
        // It should revert.
        vm.expectRevert("You shall not pass");

        // Cancel the stream.
        lockup.cancel(recipientRevertStreamId);
    }

    function test_RevertWhen_RecipientReturnsInvalidSelector()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerSender
        givenCancelableStream
        givenSTREAMINGStatus
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
    {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupBase_InvalidHookSelector.selector, address(recipientInvalidSelector)
            )
        );

        // Cancel the stream.
        lockup.cancel(recipientInvalidSelectorStreamId);
    }

    function test_WhenReentrancy()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerSender
        givenCancelableStream
        givenSTREAMINGStatus
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
        whenRecipientReturnsValidSelector
    {
        // It should make Sablier run the recipient hook.
        uint128 senderAmount = lockup.refundableAmountOf(recipientReentrantStreamId);
        uint128 recipientAmount = lockup.withdrawableAmountOf(recipientReentrantStreamId);
        vm.expectCall(
            address(recipientReentrant),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupCancel,
                (recipientReentrantStreamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // It should perform a reentrancy call to the Lockup contract.
        vm.expectCall(
            address(lockup),
            abi.encodeCall(
                ISablierLockupBase.withdraw, (recipientReentrantStreamId, address(recipientReentrant), recipientAmount)
            )
        );

        // Cancel the stream.
        lockup.cancel(recipientReentrantStreamId);

        // It should mark the stream as depleted. The reentrant recipient withdrew all the funds.
        Lockup.Status actualStatus = lockup.statusOf(recipientReentrantStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // It should make the withdrawal via the reentrancy.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(recipientReentrantStreamId);
        assertEq(actualWithdrawnAmount, recipientAmount, "withdrawnAmount");
    }

    function test_WhenNoReentrancy()
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerSender
        givenCancelableStream
        givenSTREAMINGStatus
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
        whenRecipientReturnsValidSelector
    {
        // It should refund the sender.
        uint128 senderAmount = lockup.refundableAmountOf(recipientGoodStreamId);
        expectCallToTransfer({ to: users.sender, value: senderAmount });

        // It should make Sablier run the recipient hook.
        uint128 recipientAmount = lockup.withdrawableAmountOf(recipientGoodStreamId);
        vm.expectCall(
            address(recipientGood),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupCancel,
                (recipientGoodStreamId, users.sender, senderAmount, recipientAmount)
            )
        );

        // It should emit {MetadataUpdate} and {CancelLockupStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.CancelLockupStream(
            recipientGoodStreamId, users.sender, address(recipientGood), dai, senderAmount, recipientAmount
        );
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: recipientGoodStreamId });

        // Cancel the stream.
        lockup.cancel(recipientGoodStreamId);

        // It should mark the stream as canceled.
        Lockup.Status actualStatus = lockup.statusOf(recipientGoodStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // It should make the stream as non cancelable.
        bool isCancelable = lockup.isCancelable(recipientGoodStreamId);
        assertFalse(isCancelable, "isCancelable");

        // It should update the refunded amount.
        uint128 actualRefundedAmount = lockup.getRefundedAmount(recipientGoodStreamId);
        uint128 expectedRefundedAmount = senderAmount;
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");

        // It should not burn the NFT.
        address actualNFTOwner = lockup.ownerOf({ tokenId: recipientGoodStreamId });
        address expectedNFTOwner = address(recipientGood);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
