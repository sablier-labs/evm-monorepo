// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Solarray } from "solarray/src/Solarray.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup } from "src/core/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";
import { CancelMultiple_Integration_Shared_Test } from "../../../shared/lockup/cancelMultiple.t.sol";

abstract contract CancelMultiple_Integration_Concrete_Test is
    Integration_Test,
    CancelMultiple_Integration_Shared_Test
{
    function setUp() public virtual override(Integration_Test, CancelMultiple_Integration_Shared_Test) {
        CancelMultiple_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierLockup.cancelMultiple, (testStreamIds));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_WhenZeroArrayLength() external whenNoDelegateCall {
        // It should do nothing.
        uint256[] memory streamIds = new uint256[](0);
        lockup.cancelMultiple(streamIds);
    }

    function test_RevertGiven_AtleastOneNullStream() external whenNoDelegateCall whenNonZeroArrayLength {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(testStreamIds[0], nullStreamId) });
    }

    modifier givenNoNullStreams() {
        _;
    }

    function test_RevertGiven_AtleastOneColdStream()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
    {
        uint256 earlyStreamId = createDefaultStreamWithEndTime({ endTime: defaults.CLIFF_TIME() + 1 seconds });
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() + 1 seconds });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamSettled.selector, earlyStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(testStreamIds[0], earlyStreamId) });
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
            abi.encodeWithSelector(Errors.SablierLockup_Unauthorized.selector, testStreamIds[0], users.recipient)
        );
        lockup.cancelMultiple(testStreamIds);
    }

    function test_RevertGiven_AtleastOneNonCancelableStream()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoColdStreams
        whenCallerAuthorizedForAll
    {
        uint256 notCancelableStreamId = createDefaultStreamNotCancelable();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_StreamNotCancelable.selector, notCancelableStreamId)
        );
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(testStreamIds[0], notCancelableStreamId) });
    }

    function test_GivenNoNonCancelableStreams()
        external
        whenNoDelegateCall
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoColdStreams
        whenCallerAuthorizedForAll
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should refund the sender.
        uint128 senderAmount0 = lockup.refundableAmountOf(testStreamIds[0]);
        expectCallToTransfer({ to: users.sender, value: senderAmount0 });
        uint128 senderAmount1 = lockup.refundableAmountOf(testStreamIds[1]);
        expectCallToTransfer({ to: users.sender, value: senderAmount1 });

        // It should emit {CancelLockupStream} events for all streams.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: testStreamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            asset: dai,
            senderAmount: senderAmount0,
            recipientAmount: defaults.DEPOSIT_AMOUNT() - senderAmount0
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: testStreamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            asset: dai,
            senderAmount: senderAmount1,
            recipientAmount: defaults.DEPOSIT_AMOUNT() - senderAmount1
        });

        // Cancel the streams.
        lockup.cancelMultiple(testStreamIds);

        // It should mark the streams as canceled.
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(lockup.statusOf(testStreamIds[0]), expectedStatus, "status0");
        assertEq(lockup.statusOf(testStreamIds[1]), expectedStatus, "status1");

        // It should make the streams as non cancelable.
        assertFalse(lockup.isCancelable(testStreamIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(testStreamIds[1]), "isCancelable1");

        // It should update the refunded amounts.
        assertEq(lockup.getRefundedAmount(testStreamIds[0]), senderAmount0, "refundedAmount0");
        assertEq(lockup.getRefundedAmount(testStreamIds[1]), senderAmount1, "refundedAmount1");

        // It should not burn the NFT for all streams.
        address expectedNFTOwner = users.recipient;
        assertEq(lockup.getRecipient(testStreamIds[0]), expectedNFTOwner, "NFT owner0");
        assertEq(lockup.getRecipient(testStreamIds[1]), expectedNFTOwner, "NFT owner1");
    }
}
