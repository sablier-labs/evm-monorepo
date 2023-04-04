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
    function test_ArrayCountZero() external whenNoDelegateCall {
        uint256[] memory streamIds = new uint256[](0);
        lockup.cancelMultiple(streamIds);
    }

    modifier whenArrayCountNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_OnlyNullStreams() external whenNoDelegateCall whenArrayCountNotZero {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, nullStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(nullStreamId) });
    }

    /// @dev it should revert.
    function test_RevertWhen_SomeNullStreams() external whenNoDelegateCall whenArrayCountNotZero {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, nullStreamId));
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(defaultStreamIds[0], nullStreamId) });
    }

    modifier whenOnlyNonNullStreams() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_AllStreamsNonCancelable()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenOnlyNonNullStreams
    {
        uint256 nonCancelableStreamId = createDefaultStreamNonCancelable();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNonCancelable.selector, nonCancelableStreamId)
        );
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(nonCancelableStreamId) });
    }

    /// @dev it should ignore the non-cancelable streams and cancel the cancelable streams.
    function test_RevertWhen_SomeStreamsNonCancelable()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenOnlyNonNullStreams
    {
        uint256 nonCancelableStreamId = createDefaultStreamNonCancelable();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNonCancelable.selector, nonCancelableStreamId)
        );
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(defaultStreamIds[0], nonCancelableStreamId) });
    }

    modifier whenAllStreamsCancelable() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenOnlyNonNullStreams
        whenAllStreamsCancelable
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
        whenArrayCountNotZero
        whenOnlyNonNullStreams
        whenAllStreamsCancelable
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
        whenArrayCountNotZero
        whenOnlyNonNullStreams
        whenAllStreamsCancelable
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
        whenArrayCountNotZero
        whenOnlyNonNullStreams
        whenAllStreamsCancelable
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
        whenArrayCountNotZero
        whenOnlyNonNullStreams
        whenAllStreamsCancelable
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
        whenArrayCountNotZero
        whenOnlyNonNullStreams
        whenAllStreamsCancelable
    {
        // Transfer the first stream to Eve.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    modifier whenCallerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// {CancelLockupStream} events.
    function test_CancelMultiple_Sender()
        external
        whenNoDelegateCall
        whenArrayCountNotZero
        whenOnlyNonNullStreams
        whenAllStreamsCancelable
        whenCallerAuthorizedAllStreams
    {
        changePrank({ msgSender: users.sender });
        test_CancelMultiple();
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// {CancelLockupStream} events.
    function test_CancelMultiple_Recipient()
        external
        whenNoDelegateCall
        whenOnlyNonNullStreams
        whenAllStreamsCancelable
        whenCallerAuthorizedAllStreams
    {
        test_CancelMultiple();
    }

    struct Vars {
        uint256 ongoingStreamId;
        uint40 earlyEndTime;
        uint256 endedStreamId;
        uint256[] streamIds;
        uint128 recipientAmount0;
        uint128 recipientAmount1;
        uint128 senderAmount0;
        uint128 senderAmount1;
        Lockup.Status actualStatus0;
        Lockup.Status actualStatus1;
        Lockup.Status expectedStatus;
        bool isCancelable0;
        bool isCancelable1;
        uint128 actualWithdrawnAmount0;
        uint128 actualWithdrawnAmount1;
        uint128 expectedWithdrawnAmount0;
        uint128 expectedWithdrawnAmount1;
        address actualNFTOwner0;
        address actualNFTOwner1;
        address expectedNFTOwner;
    }

    /// @dev Shared test logic for {test_CancelMultiple_Sender} and {test_CancelMultiple_Recipient}.
    function test_CancelMultiple() internal {
        Vars memory vars;

        // Use the first default stream as the ongoing stream.
        vars.ongoingStreamId = defaultStreamIds[0];

        // Create the ended stream.
        vars.earlyEndTime = DEFAULT_START_TIME + DEFAULT_TIME_WARP;
        vars.endedStreamId = createDefaultStreamWithEndTime(vars.earlyEndTime);

        // Warp to the end of the ended stream.
        vm.warp({ timestamp: vars.earlyEndTime });

        // Create the stream ids array.
        vars.streamIds = Solarray.uint256s(vars.ongoingStreamId, vars.endedStreamId);

        // Expect the ERC-20 assets to be withdrawn to the recipient.
        vars.recipientAmount0 = lockup.withdrawableAmountOf(vars.streamIds[0]);
        expectTransferCall({ to: users.recipient, amount: vars.recipientAmount0 });
        vars.recipientAmount1 = lockup.withdrawableAmountOf(vars.streamIds[1]);
        expectTransferCall({ to: users.recipient, amount: vars.recipientAmount1 });

        // Expect some ERC-20 assets to be returned to the sender (only for the ongoing stream).
        vars.senderAmount0 = DEFAULT_DEPOSIT_AMOUNT - vars.recipientAmount0;
        expectTransferCall({ to: users.sender, amount: vars.senderAmount0 });
        vars.senderAmount1 = DEFAULT_DEPOSIT_AMOUNT - vars.recipientAmount1;

        // Expect two {CancelLockupStream} events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(
            vars.streamIds[0], users.sender, users.recipient, vars.senderAmount0, vars.recipientAmount0
        );
        vm.expectEmit({ emitter: address(lockup) });
        emit CancelLockupStream(
            vars.streamIds[1], users.sender, users.recipient, vars.senderAmount1, vars.recipientAmount1
        );

        // Cancel the streams.
        lockup.cancelMultiple(vars.streamIds);

        // Assert that the streams have been marked as canceled.
        vars.actualStatus0 = lockup.getStatus(vars.streamIds[0]);
        vars.actualStatus1 = lockup.getStatus(vars.streamIds[1]);
        vars.expectedStatus = Lockup.Status.CANCELED;
        assertEq(vars.actualStatus0, vars.expectedStatus, "status0");
        assertEq(vars.actualStatus1, vars.expectedStatus, "status1");

        // Assert that the streams are not cancelable anymore.
        vars.isCancelable0 = lockup.isCancelable(vars.streamIds[0]);
        vars.isCancelable1 = lockup.isCancelable(vars.streamIds[1]);
        assertFalse(vars.isCancelable0, "isCancelable0");
        assertFalse(vars.isCancelable1, "isCancelable1");

        // Assert that the withdrawn amounts have been updated.
        vars.actualWithdrawnAmount0 = lockup.getWithdrawnAmount(vars.streamIds[0]);
        vars.actualWithdrawnAmount1 = lockup.getWithdrawnAmount(vars.streamIds[1]);
        vars.expectedWithdrawnAmount0 = vars.recipientAmount0;
        vars.expectedWithdrawnAmount1 = vars.recipientAmount1;
        assertEq(vars.actualWithdrawnAmount0, vars.expectedWithdrawnAmount0, "withdrawAmount0");
        assertEq(vars.actualWithdrawnAmount1, vars.expectedWithdrawnAmount1, "withdrawAmount1");

        // Assert that the NFTs have not been burned.
        vars.actualNFTOwner0 = lockup.getRecipient(vars.streamIds[0]);
        vars.actualNFTOwner1 = lockup.getRecipient(vars.streamIds[1]);
        vars.expectedNFTOwner = users.recipient;
        assertEq(vars.actualNFTOwner0, vars.expectedNFTOwner, "NFT owner0");
        assertEq(vars.actualNFTOwner1, vars.expectedNFTOwner, "NFT owner1");
    }
}
