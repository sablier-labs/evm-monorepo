// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Solarray } from "solarray/src/Solarray.sol";

import { ISablierLockupBase } from "src/core/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup } from "src/core/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract CancelMultiple_Integration_Concrete_Test is Integration_Test {
    // The original time when the tests started.
    uint40 internal originalTime;

    function setUp() public virtual override {
        originalTime = getBlockTimestamp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierLockupBase.cancelMultiple, (cancelMultipleStreamIds));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_WhenZeroArrayLength() external whenNoDelegateCall {
        // It should do nothing.
        uint256[] memory streamIds = new uint256[](0);
        lockup.cancelMultiple(streamIds);
    }

    function test_RevertGiven_AtleastOneNullStream() external whenNoDelegateCall whenNonZeroArrayLength {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(cancelMultipleStreamIds[0], nullStreamId) });
    }

    function test_RevertGiven_AtleastOneColdStream()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
    {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() + 1 seconds });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_StreamSettled.selector, earlyEndtimeStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(cancelMultipleStreamIds[0], earlyEndtimeStreamId) });
    }

    function test_RevertWhen_CallerUnauthorizedForAny()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoColdStreams
    {
        // Make the Recipient the caller in this test.
        resetPrank({ msgSender: users.recipient });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupBase_Unauthorized.selector, cancelMultipleStreamIds[0], users.recipient
            )
        );
        lockup.cancelMultiple(cancelMultipleStreamIds);
    }

    function test_RevertGiven_AtleastOneNonCancelableStream()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoColdStreams
        whenCallerAuthorizedForAllStreams
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_StreamNotCancelable.selector, notCancelableStreamId)
        );
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(cancelMultipleStreamIds[0], notCancelableStreamId) });
    }

    function test_GivenNoNonCancelableStreams()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoColdStreams
        whenCallerAuthorizedForAllStreams
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should refund the sender.
        uint128 senderAmount0 = lockup.refundableAmountOf(cancelMultipleStreamIds[0]);
        expectCallToTransfer({ to: users.sender, value: senderAmount0 });
        uint128 senderAmount1 = lockup.refundableAmountOf(cancelMultipleStreamIds[1]);
        expectCallToTransfer({ to: users.sender, value: senderAmount1 });

        // It should emit {CancelLockupStream} events for all streams.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.CancelLockupStream({
            streamId: cancelMultipleStreamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            asset: dai,
            senderAmount: senderAmount0,
            recipientAmount: defaults.DEPOSIT_AMOUNT() - senderAmount0
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.CancelLockupStream({
            streamId: cancelMultipleStreamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            asset: dai,
            senderAmount: senderAmount1,
            recipientAmount: defaults.DEPOSIT_AMOUNT() - senderAmount1
        });

        // Cancel the streams.
        lockup.cancelMultiple(cancelMultipleStreamIds);

        // It should mark the streams as canceled.
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(lockup.statusOf(cancelMultipleStreamIds[0]), expectedStatus, "status0");
        assertEq(lockup.statusOf(cancelMultipleStreamIds[1]), expectedStatus, "status1");

        // It should make the streams as non cancelable.
        assertFalse(lockup.isCancelable(cancelMultipleStreamIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(cancelMultipleStreamIds[1]), "isCancelable1");

        // It should update the refunded amounts.
        assertEq(lockup.getRefundedAmount(cancelMultipleStreamIds[0]), senderAmount0, "refundedAmount0");
        assertEq(lockup.getRefundedAmount(cancelMultipleStreamIds[1]), senderAmount1, "refundedAmount1");

        // It should not burn the NFT for all streams.
        address expectedNFTOwner = users.recipient;
        assertEq(lockup.getRecipient(cancelMultipleStreamIds[0]), expectedNFTOwner, "NFT owner0");
        assertEq(lockup.getRecipient(cancelMultipleStreamIds[1]), expectedNFTOwner, "NFT owner1");
    }
}
