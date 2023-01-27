// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";

import { Unit_Test } from "../../../Unit.t.sol";
import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";

abstract contract CancelMultiple_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank({ who: users.recipient });
    }

    /// @dev it should do nothing.
    function test_RevertWhen_OnlyNullStreams() external {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(nullStreamId);
        lockup.cancelMultiple(streamIds);
    }

    /// @dev it should ignore the null streams and cancel the non-null ones.
    function test_RevertWhen_SomeNullStreams() external {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], nullStreamId);
        lockup.cancelMultiple(streamIds);
        Status actualStatus = lockup.getStatus(defaultStreamIds[0]);
        Status expectedStatus = Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier onlyNonNullStreams() {
        _;
    }

    /// @dev it should do nothing.
    function test_RevertWhen_AllStreamsNonCancelable() external onlyNonNullStreams {
        // Create the non-cancelable stream.
        uint256 nonCancelableStreamId = createDefaultStreamNonCancelable();

        // Run the test.
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(nonCancelableStreamId) });
    }

    /// @dev it should ignore the non-cancelable streams and cancel the cancelable streams.
    function test_RevertWhen_SomeStreamsNonCancelable() external onlyNonNullStreams {
        // Create the non-cancelable stream.
        uint256 nonCancelableStreamId = createDefaultStreamNonCancelable();

        // Run the test.
        lockup.cancelMultiple({ streamIds: Solarray.uint256s(defaultStreamIds[0], nonCancelableStreamId) });

        // Assert that the cancelable stream was canceled.
        Status actualStatus = lockup.getStatus(defaultStreamIds[0]);
        Status expectedStatus = Status.CANCELED;
        assertEq(actualStatus, expectedStatus, "status0");

        // Assert that the non-cancelable stream was not canceled.
        Status status = lockup.getStatus(nonCancelableStreamId);
        assertEq(status, Status.ACTIVE, "status1");
    }

    modifier allStreamsCancelable() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Make Eve the caller in this test.
        changePrank({ who: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_ApprovedOperator()
        external
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Approve the operator for all streams.
        lockup.setApprovalForAll({ operator: users.operator, _approved: true });

        // Make the approved operator the caller in this test.
        changePrank({ who: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
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
        onlyNonNullStreams
        allStreamsCancelable
    {
        changePrank({ who: users.eve });

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
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Approve the operator to handle the first stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamIds[0] });

        // Make the approved operator the caller in this test.
        changePrank({ who: users.operator });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        lockup.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
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
    function test_CancelMultiple_Sender() external onlyNonNullStreams allStreamsCancelable callerAuthorizedAllStreams {
        changePrank({ who: users.sender });
        test_CancelMultiple();
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// CancelLockupStream events.
    function test_CancelMultiple_Recipient()
        external
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
        uint40 earlyStopTime = DEFAULT_START_TIME + DEFAULT_TIME_WARP;
        uint256 endedStreamId = createDefaultStreamWithStopTime(earlyStopTime);

        // Warp to the end of the ended stream.
        vm.warp({ timestamp: earlyStopTime });

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(ongoingStreamId, endedStreamId);

        // Expect the ERC-20 assets to be withdrawn to the recipient.
        uint128 recipientAmount0 = lockup.getWithdrawableAmount(streamIds[0]);
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.recipient, recipientAmount0)));
        uint128 recipientAmount1 = lockup.getWithdrawableAmount(streamIds[1]);
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.recipient, recipientAmount1)));

        // Expect some ERC-20 assets to be returned to the sender only for the ongoing stream.
        uint128 senderAmount0 = DEFAULT_NET_DEPOSIT_AMOUNT - recipientAmount0;
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.sender, senderAmount0)));
        uint128 senderAmount1 = DEFAULT_NET_DEPOSIT_AMOUNT - recipientAmount1;

        // Expect two {CancelLockupStream} events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CancelLockupStream(streamIds[0], users.sender, users.recipient, senderAmount0, recipientAmount0);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CancelLockupStream(streamIds[1], users.sender, users.recipient, senderAmount1, recipientAmount1);

        // Cancel the streams.
        lockup.cancelMultiple(streamIds);

        // Assert that the streams were marked as canceled.
        Status actualStatus0 = lockup.getStatus(streamIds[0]);
        Status actualStatus1 = lockup.getStatus(streamIds[1]);
        Status expectedStatus = Status.CANCELED;
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(streamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(streamIds[1]);
        uint128 expectedWithdrawnAmount0 = recipientAmount0;
        uint128 expectedWithdrawnAmount1 = recipientAmount1;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0, "withdrawAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1, "withdrawAmount1");

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = lockup.getRecipient(streamIds[0]);
        address actualNFTOwner1 = lockup.getRecipient(streamIds[1]);
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, expectedNFTOwner, "NFT owner0");
        assertEq(actualNFTOwner1, expectedNFTOwner, "NFT owner1");
    }
}
