// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CancelMultiple_Integration_Concrete_Test is Integration_Test {
    // An array of stream IDs to be canceled.
    uint256[] internal streamIds;

    function setUp() public virtual override {
        Integration_Test.setUp();

        streamIds.push(createDefaultStream());

        // Create the second stream with an end time double that of the default stream so that the refund amounts are
        // different.
        streamIds.push(createDefaultStreamWithEndTime(defaults.END_TIME() + defaults.TOTAL_DURATION()));
    }

    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({ callData: abi.encodeCall(lockup.cancelMultiple, streamIds) });
    }

    function test_WhenZeroArrayLength() external whenNoDelegateCall {
        // It should do nothing.
        uint256[] memory nullStreamIds = new uint256[](0);
        uint128[] memory refundedAmounts = lockup.cancelMultiple(nullStreamIds);

        assertEq(refundedAmounts.length, 0, "refundedAmounts.length");
    }

    function test_WhenOneStreamReverts() external whenNoDelegateCall whenNonZeroArrayLength {
        // Create a cancelable stream using a different sender so that users.sender cannot cancel it.
        uint256 revertingStreamId = createDefaultStreamWithUsers(users.recipient, users.alice);
        streamIds.push(revertingStreamId);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        uint128 expectedSenderAmount = defaults.DEPOSIT_AMOUNT() - defaults.WITHDRAW_AMOUNT();

        // It should emit {CancelLockupStream} events for non-reverting streams.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.CancelLockupStream({
            streamId: streamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            token: dai,
            senderAmount: expectedSenderAmount,
            recipientAmount: defaults.WITHDRAW_AMOUNT()
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.CancelLockupStream({
            streamId: streamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            token: dai,
            senderAmount: expectedSenderAmount,
            recipientAmount: defaults.WITHDRAW_AMOUNT()
        });

        // It should emit {InvalidStreamInCancelMultiple} event for reverting stream.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.InvalidStreamInCancelMultiple({
            streamId: revertingStreamId,
            revertData: abi.encodeWithSelector(
                Errors.SablierLockupBase_Unauthorized.selector, revertingStreamId, users.sender
            )
        });

        // Cancel the streams.
        uint128[] memory refundedAmounts = lockup.cancelMultiple(streamIds);

        // It should return the expected refunded amounts.
        assertEq(refundedAmounts.length, 3, "refundedAmounts.length");
        assertEq(refundedAmounts[0], expectedSenderAmount, "refundedAmount0");
        assertEq(refundedAmounts[1], expectedSenderAmount, "refundedAmount1");
        assertEq(refundedAmounts[2], 0, "refundedAmount2");

        // It should mark the streams as canceled only for non-reverting streams.
        assertEq(lockup.statusOf(streamIds[0]), Lockup.Status.CANCELED, "status0");
        assertEq(lockup.statusOf(streamIds[1]), Lockup.Status.CANCELED, "status1");
        assertEq(lockup.statusOf(streamIds[2]), Lockup.Status.STREAMING, "status2");

        // It should mark the streams as non cancelable only for non-reverting streams.
        assertFalse(lockup.isCancelable(streamIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(streamIds[1]), "isCancelable1");
        assertTrue(lockup.isCancelable(streamIds[2]), "isCancelable2");

        // It should update the refunded amounts only for non-reverting streams.
        assertEq(lockup.getRefundedAmount(streamIds[0]), expectedSenderAmount, "refundedAmount0");
        assertEq(lockup.getRefundedAmount(streamIds[1]), expectedSenderAmount, "refundedAmount1");
        assertEq(lockup.getRefundedAmount(streamIds[2]), 0, "refundedAmount2");
    }

    function test_WhenNoStreamsRevert() external whenNoDelegateCall whenNonZeroArrayLength {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should refund the sender.
        uint128 senderAmount0 = lockup.refundableAmountOf(streamIds[0]);
        expectCallToTransfer({ to: users.sender, value: senderAmount0 });
        uint128 senderAmount1 = lockup.refundableAmountOf(streamIds[1]);
        expectCallToTransfer({ to: users.sender, value: senderAmount1 });

        // It should emit {CancelLockupStream} events for all streams.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.CancelLockupStream({
            streamId: streamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            token: dai,
            senderAmount: senderAmount0,
            recipientAmount: defaults.DEPOSIT_AMOUNT() - senderAmount0
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.CancelLockupStream({
            streamId: streamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            token: dai,
            senderAmount: senderAmount1,
            recipientAmount: defaults.DEPOSIT_AMOUNT() - senderAmount1
        });

        // Cancel the streams.
        uint128[] memory refundedAmounts = lockup.cancelMultiple(streamIds);

        // It should return the expected refunded amounts.
        assertEq(refundedAmounts.length, 2, "refundedAmounts.length");
        assertEq(refundedAmounts[0], senderAmount0, "refundedAmount0");
        assertEq(refundedAmounts[1], senderAmount1, "refundedAmount1");

        // It should mark the streams as canceled.
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(lockup.statusOf(streamIds[0]), expectedStatus, "status0");
        assertEq(lockup.statusOf(streamIds[1]), expectedStatus, "status1");

        // It should make the streams as non cancelable.
        assertFalse(lockup.isCancelable(streamIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(streamIds[1]), "isCancelable1");

        // It should update the refunded amounts.
        assertEq(lockup.getRefundedAmount(streamIds[0]), senderAmount0, "refundedAmount0");
        assertEq(lockup.getRefundedAmount(streamIds[1]), senderAmount1, "refundedAmount1");

        // It should not burn the NFT for any stream.
        address expectedNFTOwner = users.recipient;
        assertEq(lockup.getRecipient(streamIds[0]), expectedNFTOwner, "NFT owner0");
        assertEq(lockup.getRecipient(streamIds[1]), expectedNFTOwner, "NFT owner1");
    }
}
