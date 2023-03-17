// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Unit_Test } from "../../../Unit.t.sol";
import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";

abstract contract CancelMultiple_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCall() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.cancelMultiple, (defaultStreamIds));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    /// @dev it should do nothing.
    function test_RevertWhen_ArrayCountZero() external whenNoDelegateCall {
        uint256[] memory streamIds = new uint256[](0);
        lockup.cancelMultiple(streamIds);
    }

    modifier arrayCountNotZero() {
        _;
    }

    /// @dev it should do nothing.
    function test_RevertWhen_OnlyNullStreams() external whenNoDelegateCall arrayCountNotZero {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(nullStreamId);
        lockup.cancelMultiple(streamIds);
    }

    /// @dev it should ignore the null streams and cancel the non-null ones.
    function test_RevertWhen_SomeNullStreams() external whenNoDelegateCall arrayCountNotZero {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], nullStreamId);
        lockup.cancelMultiple(streamIds);
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamIds[0]);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier onlyNonNullStreams() {
        _;
    }

    /// @dev it should do nothing.
    function test_RevertWhen_AllStreamsNonCancelable()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
    {
        // Create the non-cancelable stream.
        uint256 nonCancelableStreamId = createDefaultStreamNonCancelable();

        // Run the test.
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(nonCancelableStreamId) });
    }

    /// @dev it should ignore the non-cancelable streams and cancel the cancelable streams.
    function test_RevertWhen_SomeStreamsNonCancelable()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
    {
        // Create the non-cancelable stream.
        uint256 nonCancelableStreamId = createDefaultStreamNonCancelable();

        // Run the test.
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(defaultStreamIds[0], nonCancelableStreamId) });

        // Assert that the cancelable stream has been canceled.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamIds[0]);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus, "status0");

        // Assert that the non-cancelable stream has not been canceled.
        Lockup.Status status = lockup.getStatus(nonCancelableStreamId);
        assertEq(status, Lockup.Status.ACTIVE, "status1");
    }

    modifier allStreamsCancelable() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_ApprovedOperator()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Approve the operator for all streams.
        lockup.setApprovalForAll({ operator: users.operator, _approved: true });

        // Make the approved operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Transfer the streams to Alice.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
        allStreamsCancelable
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

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedSomeStreams_ApprovedOperator()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Approve the operator to handle the first stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamIds[0] });

        // Make the approved operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Transfer the first stream to Eve.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    modifier callerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// CancelLockupStream events.
    function test_CancelMultiple_Sender()
        external
        whenNoDelegateCall
        arrayCountNotZero
        onlyNonNullStreams
        allStreamsCancelable
        callerAuthorizedAllStreams
    {
        changePrank({ msgSender: users.sender });
        test_CancelMultiple();
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// CancelLockupStream events.
    function test_CancelMultiple_Recipient()
        external
        whenNoDelegateCall
        onlyNonNullStreams
        allStreamsCancelable
        callerAuthorizedAllStreams
    {
        test_CancelMultiple();
    }

    /// @dev Shared test logic for `test_CancelMultiple_Sender` and `test_CancelMultiple_Recipient`.
    function test_CancelMultiple() internal {
        // Use the first default stream as the ongoing stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Create the ended stream.
        uint40 earlyEndTime = DEFAULT_START_TIME + DEFAULT_TIME_WARP;
        uint256 endedStreamId = createDefaultStreamWithEndTime(earlyEndTime);

        // Warp to the end of the ended stream.
        vm.warp({ timestamp: earlyEndTime });

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(ongoingStreamId, endedStreamId);

        // Expect the ERC-20 assets to be withdrawn to the recipient.
        uint128 recipientAmount0 = lockup.withdrawableAmountOf(streamIds[0]);
        expectTransferCall({ to: users.recipient, amount: recipientAmount0 });
        uint128 recipientAmount1 = lockup.withdrawableAmountOf(streamIds[1]);
        expectTransferCall({ to: users.recipient, amount: recipientAmount1 });

        // Expect some ERC-20 assets to be returned to the sender only for the ongoing stream.
        uint128 senderAmount0 = DEFAULT_DEPOSIT_AMOUNT - recipientAmount0;
        expectTransferCall({ to: users.sender, amount: senderAmount0 });
        uint128 senderAmount1 = DEFAULT_DEPOSIT_AMOUNT - recipientAmount1;

        // Expect two {CancelLockupStream} events to be emitted.
        vm.expectEmit();
        emit CancelLockupStream(streamIds[0], users.sender, users.recipient, senderAmount0, recipientAmount0);
        vm.expectEmit();
        emit CancelLockupStream(streamIds[1], users.sender, users.recipient, senderAmount1, recipientAmount1);

        // Cancel the streams.
        lockup.cancelMultiple(streamIds);

        // Assert that the streams have been marked as canceled.
        Lockup.Status actualStatus0 = lockup.getStatus(streamIds[0]);
        Lockup.Status actualStatus1 = lockup.getStatus(streamIds[1]);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(streamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(streamIds[1]);
        uint128 expectedWithdrawnAmount0 = recipientAmount0;
        uint128 expectedWithdrawnAmount1 = recipientAmount1;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0, "withdrawAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1, "withdrawAmount1");

        // Assert that the NFTs have not been burned.
        address actualNFTOwner0 = lockup.getRecipient(streamIds[0]);
        address actualNFTOwner1 = lockup.getRecipient(streamIds[1]);
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, expectedNFTOwner, "NFT owner0");
        assertEq(actualNFTOwner1, expectedNFTOwner, "NFT owner1");
    }
}
