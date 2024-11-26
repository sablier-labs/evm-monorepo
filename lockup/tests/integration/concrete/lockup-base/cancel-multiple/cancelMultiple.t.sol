// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Solarray } from "solarray/src/Solarray.sol";

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
        lockup.cancelMultiple(nullStreamIds);
    }

    function test_RevertGiven_AtleastOneNullStream() external whenNoDelegateCall whenNonZeroArrayLength {
        expectRevert_Null({
            callData: abi.encodeCall(lockup.cancelMultiple, Solarray.uint256s(streamIds[0], nullStreamId))
        });
    }

    function test_RevertGiven_AtleastOneColdStream()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
    {
        uint40 earlyEndTime = defaults.END_TIME() - 10;
        uint256 earlyEndtimeStreamId = createDefaultStreamWithEndTime(earlyEndTime);
        vm.warp({ newTimestamp: earlyEndTime + 1 seconds });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_StreamSettled.selector, earlyEndtimeStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(streamIds[0], earlyEndtimeStreamId) });
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
            abi.encodeWithSelector(Errors.SablierLockupBase_Unauthorized.selector, streamIds[0], users.recipient)
        );
        lockup.cancelMultiple(streamIds);
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
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(streamIds[0], notCancelableStreamId) });
    }

    function test_GivenAllStreamsCancelable()
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
        lockup.cancelMultiple(streamIds);

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

        // It should not burn the NFT for all streams.
        address expectedNFTOwner = users.recipient;
        assertEq(lockup.getRecipient(streamIds[0]), expectedNFTOwner, "NFT owner0");
        assertEq(lockup.getRecipient(streamIds[1]), expectedNFTOwner, "NFT owner1");
    }
}
