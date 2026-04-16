// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { ISablierLockupRecipient } from "src/interfaces/ISablierLockupRecipient.sol";
import { Lockup } from "src/types/Lockup.sol";

import { Integration_Test } from "../../Integration.t.sol";

abstract contract Cancel_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_Cancel_StatusPending(uint256 timeJump)
        external
        whenNoDelegateCall
        givenNotNull
        givenWarmStream
        whenCallerSender
        givenCancelableStream
    {
        timeJump = _bound(timeJump, 1 seconds, 100 weeks);

        // Rewind time to the past.
        rewind(timeJump);

        uint256 previousAggregateAmount = lockup.aggregateAmount(dai);

        // Cancel the stream.
        uint128 refundedAmount = lockup.cancel(ids.defaultStream);

        // It should mark the stream as depleted.
        Lockup.Status actualStatus = lockup.statusOf(ids.defaultStream);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // It should make the stream not cancelable.
        bool isCancelable = lockup.isCancelable(ids.defaultStream);
        assertFalse(isCancelable, "isCancelable");

        // It should update the aggregate amount.
        assertEq(lockup.aggregateAmount(dai), previousAggregateAmount - refundedAmount, "aggregateAmount");
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the block timestamp
    /// - With and without withdrawals
    function testFuzz_Cancel(
        uint256 timeJump,
        uint128 withdrawAmount
    )
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
        whenRecipientNotReentrant
    {
        timeJump = _bound(timeJump, defaults.WARP_26_PERCENT_DURATION(), defaults.TOTAL_DURATION() - 1 seconds);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(ids.recipientGoodStream);
        withdrawAmount = boundUint128(withdrawAmount, 0, streamedAmount);

        // Make the withdrawal only if the amount is greater than zero.
        if (withdrawAmount > 0) {
            lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
                streamId: ids.recipientGoodStream,
                to: address(recipientGood),
                amount: withdrawAmount
            });
        }

        uint256 previousAggregateAmount = lockup.aggregateAmount(dai);

        // Expect the tokens to be refunded to the Sender.
        uint128 senderAmount = lockup.refundableAmountOf(ids.recipientGoodStream);
        expectCallToTransfer({ to: users.sender, value: senderAmount });

        // Expect the recipient to be called.
        uint128 recipientAmount = lockup.withdrawableAmountOf(ids.recipientGoodStream);
        vm.expectCall(
            address(recipientGood),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupCancel,
                (ids.recipientGoodStream, users.sender, senderAmount, recipientAmount)
            )
        );

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CancelLockupStream(
            ids.recipientGoodStream,
            users.sender,
            address(recipientGood),
            dai,
            senderAmount,
            recipientAmount
        );
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: ids.recipientGoodStream });

        // Cancel the stream.
        uint128 refundedAmount = lockup.cancel(ids.recipientGoodStream);

        // It should match the amount refunded with the expected value.
        assertEq(refundedAmount, senderAmount, "refundedAmount");

        // It should mark the stream as "DEPLETED" if recipient amount is zero, otherwise "CANCELED".
        Lockup.Status actualStatus = lockup.statusOf(ids.recipientGoodStream);
        Lockup.Status expectedStatus = recipientAmount == 0 ? Lockup.Status.DEPLETED : Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // It should make the stream not cancelable.
        bool isCancelable = lockup.isCancelable(ids.recipientGoodStream);
        assertFalse(isCancelable, "isCancelable");

        // It should update the aggregate amount.
        assertEq(lockup.aggregateAmount(dai), previousAggregateAmount - refundedAmount, "aggregateAmount");

        // It should not burn the NFT.
        address actualNFTOwner = lockup.ownerOf({ tokenId: ids.recipientGoodStream });
        address expectedNFTOwner = address(recipientGood);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
