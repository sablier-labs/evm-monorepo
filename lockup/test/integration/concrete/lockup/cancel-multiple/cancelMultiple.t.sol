// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";
import { CancelMultiple_Integration_Shared_Test } from "../../../shared/lockup/cancelMultiple.t.sol";

abstract contract CancelMultiple_Integration_Concrete_Test is
    Integration_Test,
    CancelMultiple_Integration_Shared_Test
{
    function setUp() public virtual override(Integration_Test, CancelMultiple_Integration_Shared_Test) {
        CancelMultiple_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCalled() external whenNotDelegateCalled {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.cancelMultiple, (testStreamIds));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_CancelMultiple_ArrayCountZero() external whenNotDelegateCalled {
        uint256[] memory streamIds = new uint256[](0);
        lockup.cancelMultiple(streamIds);
    }

    function test_RevertWhen_OnlyNull() external whenNotDelegateCalled whenArrayCountNotZero {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(nullStreamId) });
    }

    function test_RevertWhen_SomeNull() external whenNotDelegateCalled whenArrayCountNotZero {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(testStreamIds[0], nullStreamId) });
    }

    function test_RevertWhen_AllStreamsCold() external whenNotDelegateCalled whenArrayCountNotZero whenNoNull {
        vm.warp({ timestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamSettled.selector, testStreamIds[0]));
        lockup.cancelMultiple({ streamIds: testStreamIds });
    }

    function test_RevertWhen_SomeStreamsCold() external whenNotDelegateCalled whenArrayCountNotZero whenNoNull {
        uint256 earlyStreamId = createDefaultStreamWithEndTime({ endTime: defaults.CLIFF_TIME() + 1 seconds });
        vm.warp({ timestamp: defaults.CLIFF_TIME() + 1 seconds });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamSettled.selector, earlyStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(testStreamIds[0], earlyStreamId) });
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.eve)
        );
        lockup.cancelMultiple(testStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_ApprovedOperator()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Approve the operator for all streams.
        changePrank({ msgSender: users.recipient });
        lockup.setApprovalForAll({ operator: users.operator, approved: true });

        // Make the approved operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.operator)
        );
        lockup.cancelMultiple(testStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Transfer the streams to Alice.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: testStreamIds[0] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: testStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.recipient)
        );
        lockup.cancelMultiple(testStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        changePrank({ msgSender: users.eve });

        // Create a stream with Eve as the stream's sender.
        uint256 eveStreamId = createDefaultStreamWithSender(users.eve);

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, testStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.eve)
        );
        lockup.cancelMultiple(streamIds);
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_ApprovedOperator()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Approve the operator to handle the first stream.
        changePrank({ msgSender: users.recipient });
        lockup.approve({ to: users.operator, tokenId: testStreamIds[0] });

        // Make the approved operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.operator)
        );
        lockup.cancelMultiple(testStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Transfer the first stream to Eve.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: testStreamIds[0] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.recipient)
        );
        lockup.cancelMultiple(testStreamIds);
    }

    function test_RevertWhen_AllStreamsNotCancelable()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerAuthorizedAllStreams
    {
        uint256 notCancelableStreamId = createDefaultStreamNotCancelable();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCancelable.selector, notCancelableStreamId)
        );
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(notCancelableStreamId) });
    }

    function test_RevertWhen_SomeStreamsNotCancelable()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerAuthorizedAllStreams
    {
        uint256 notCancelableStreamId = createDefaultStreamNotCancelable();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCancelable.selector, notCancelableStreamId)
        );
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(testStreamIds[0], notCancelableStreamId) });
    }

    function test_CancelMultiple()
        external
        whenNotDelegateCalled
        whenNoNull
        whenAllStreamsWarm
        whenCallerAuthorizedAllStreams
        whenAllStreamsCancelable
    {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Expect the assets to be refunded to the stream's sender.
        uint128 senderAmount0 = lockup.refundableAmountOf(testStreamIds[0]);
        expectCallToTransfer({ to: users.sender, amount: senderAmount0 });
        uint128 senderAmount1 = lockup.refundableAmountOf(testStreamIds[1]);
        expectCallToTransfer({ to: users.sender, amount: senderAmount1 });

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: testStreamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: senderAmount0,
            recipientAmount: defaults.DEPOSIT_AMOUNT() - senderAmount0
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: testStreamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: senderAmount1,
            recipientAmount: defaults.DEPOSIT_AMOUNT() - senderAmount1
        });

        // Cancel the streams.
        lockup.cancelMultiple(testStreamIds);

        // Assert that the streams have been marked as canceled.
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(lockup.statusOf(testStreamIds[0]), expectedStatus, "status0");
        assertEq(lockup.statusOf(testStreamIds[1]), expectedStatus, "status1");

        // Assert that the streams are not cancelable anymore.
        assertFalse(lockup.isCancelable(testStreamIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(testStreamIds[1]), "isCancelable1");

        // Assert that the refunded amounts have been updated.
        assertEq(lockup.getRefundedAmount(testStreamIds[0]), senderAmount0, "refundedAmount0");
        assertEq(lockup.getRefundedAmount(testStreamIds[1]), senderAmount1, "refundedAmount1");

        // Assert that the NFTs have not been burned.
        address expectedNFTOwner = users.recipient;
        assertEq(lockup.getRecipient(testStreamIds[0]), expectedNFTOwner, "NFT owner0");
        assertEq(lockup.getRecipient(testStreamIds[1]), expectedNFTOwner, "NFT owner1");
    }
}
