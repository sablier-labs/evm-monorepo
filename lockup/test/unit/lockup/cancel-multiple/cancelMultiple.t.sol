// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Unit_Test } from "../../Unit.t.sol";
import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";

abstract contract CancelMultiple_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        createDefaultStreams();
    }

    function test_RevertWhen_DelegateCall() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.cancelMultiple, (defaultStreamIds));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_CancelMultiple_ArrayCountZero() external whenNoDelegateCall {
        uint256[] memory streamIds = new uint256[](0);
        lockup.cancelMultiple(streamIds);
    }

    modifier whenArrayCountNotZero() {
        _;
    }

    function test_RevertWhen_OnlyNull() external whenNoDelegateCall whenArrayCountNotZero {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(nullStreamId) });
    }

    function test_RevertWhen_SomeNull() external whenNoDelegateCall whenArrayCountNotZero {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(defaultStreamIds[0], nullStreamId) });
    }

    modifier whenNoNull() {
        _;
    }

    function test_RevertWhen_AllStreamsCold() external whenNoDelegateCall whenArrayCountNotZero whenNoNull {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamCold.selector, defaultStreamIds[0]));
        lockup.cancelMultiple({ streamIds: defaultStreamIds });
    }

    function test_RevertWhen_SomeStreamsCold() external whenNoDelegateCall whenArrayCountNotZero whenNoNull {
        uint256 earlyStreamId = createDefaultStreamWithEndTime({ endTime: DEFAULT_CLIFF_TIME + 1 seconds });
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME + 1 seconds });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamCold.selector, earlyStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(defaultStreamIds[0], earlyStreamId) });
    }

    modifier whenAllStreamsWarm() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_ApprovedOperator()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Approve the operator for all streams.
        changePrank({ msgSender: users.recipient });
        lockup.setApprovalForAll({ operator: users.operator, _approved: true });

        // Make the approved operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Transfer the streams to Alice.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        changePrank({ msgSender: users.eve });

        // Create a stream with Eve as the sender.
        uint256 eveStreamId = createDefaultStreamWithSender(users.eve);

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.cancelMultiple(streamIds);
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_ApprovedOperator()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Approve the operator to handle the first stream.
        changePrank({ msgSender: users.recipient });
        lockup.approve({ to: users.operator, tokenId: defaultStreamIds[0] });

        // Make the approved operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerUnauthorized
    {
        // Transfer the first stream to Eve.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    modifier whenCallerAuthorizedAllStreams() {
        _;
        createDefaultStreams();
        changePrank({ msgSender: users.recipient });
        _;
    }

    function test_RevertWhen_AllStreamsNotCancelable()
        external
        whenNoDelegateCall
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
        whenNoDelegateCall
        whenArrayCountNotZero
        whenNoNull
        whenAllStreamsWarm
        whenCallerAuthorizedAllStreams
    {
        uint256 notCancelableStreamId = createDefaultStreamNotCancelable();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCancelable.selector, notCancelableStreamId)
        );
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(defaultStreamIds[0], notCancelableStreamId) });
    }

    modifier whenAllStreamsCancelable() {
        _;
    }

    function test_CancelMultiple()
        external
        whenNoDelegateCall
        whenNoNull
        whenAllStreamsWarm
        whenCallerAuthorizedAllStreams
        whenAllStreamsCancelable
    {
        // Simulate the passage of time.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Expect the assets to be refunded to the sender.
        uint128 senderAmount0 = lockup.refundableAmountOf(defaultStreamIds[0]);
        expectTransferCall({ to: users.sender, amount: senderAmount0 });
        uint128 senderAmount1 = lockup.refundableAmountOf(defaultStreamIds[1]);
        expectTransferCall({ to: users.sender, amount: senderAmount1 });

        // Expect multiple events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: defaultStreamIds[0],
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: senderAmount0,
            recipientAmount: DEFAULT_DEPOSIT_AMOUNT - senderAmount0
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream({
            streamId: defaultStreamIds[1],
            sender: users.sender,
            recipient: users.recipient,
            senderAmount: senderAmount1,
            recipientAmount: DEFAULT_DEPOSIT_AMOUNT - senderAmount0
        });

        // Cancel the streams.
        lockup.cancelMultiple(defaultStreamIds);

        // Assert that the streams have been marked as canceled.
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(lockup.statusOf(defaultStreamIds[0]), expectedStatus, "status0");
        assertEq(lockup.statusOf(defaultStreamIds[1]), expectedStatus, "status1");

        // Assert that the streams are not cancelable anymore.
        assertFalse(lockup.isCancelable(defaultStreamIds[0]), "isCancelable0");
        assertFalse(lockup.isCancelable(defaultStreamIds[1]), "isCancelable1");

        // Assert that the refunded amounts have been updated.
        assertEq(lockup.getRefundedAmount(defaultStreamIds[0]), senderAmount0, "refundedAmount0");
        assertEq(lockup.getRefundedAmount(defaultStreamIds[1]), senderAmount1, "refundedAmount1");

        // Assert that the NFTs have not been burned.
        address expectedNFTOwner = users.recipient;
        assertEq(lockup.getRecipient(defaultStreamIds[0]), expectedNFTOwner, "NFT owner0");
        assertEq(lockup.getRecipient(defaultStreamIds[1]), expectedNFTOwner, "NFT owner1");
    }

    /// @dev Creates the default streams used throughout the tests.
    function createDefaultStreams() internal {
        defaultStreamIds = new uint256[](2);
        defaultStreamIds[0] = createDefaultStream();
        defaultStreamIds[1] = createDefaultStream();
    }
}
