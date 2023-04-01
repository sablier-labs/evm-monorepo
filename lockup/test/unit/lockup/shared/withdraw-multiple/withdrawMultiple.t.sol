// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract WithdrawMultiple_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Define the default amounts, since most tests need them.
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2Lockup.withdrawMultiple, (defaultStreamIds, users.recipient, defaultAmounts));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ToZeroAddress() external whenNoDelegateCall {
        vm.expectRevert(Errors.SablierV2Lockup_WithdrawToZeroAddress.selector);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: address(0), amounts: defaultAmounts });
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ArrayCountsNotEqual() external whenNoDelegateCall whenToNonZeroAddress {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawArrayCountsNotEqual.selector, streamIds.length, amounts.length
            )
        );
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenArrayCountsNotEqual() {
        _;
    }

    /// @dev it should do nothing.
    function test_ArrayCountsZero() external whenNoDelegateCall whenToNonZeroAddress {
        uint256[] memory streamIds = new uint256[](0);
        uint128[] memory amounts = new uint128[](0);
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenArrayCountsNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_OnlyNullStreams()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
    {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, nullStreamId));
        lockup.withdrawMultiple({
            streamIds: Solarray.uint256s(nullStreamId),
            to: users.recipient,
            amounts: Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT)
        });
    }

    /// @dev it should revert.
    function test_RevertWhen_SomeNullStreams()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
    {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], nullStreamId);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Expect a {StreamNotActive} error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, nullStreamId));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier whenOnlyNonNullStreams() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_Sender()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
    {
        // Make the sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.sender)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.sender, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
    {
        // Transfer all streams to Alice.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
    {
        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = createDefaultStreamWithRecipient(users.eve);

        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
    {
        // Transfer one of the streams to Eve.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier whenCallerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function test_WithdrawMultiple_CallerApprovedOperator()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
        whenCallerAuthorizedAllStreams
    {
        // Approve the operator for all streams.
        lockup.setApprovalForAll(users.operator, true);

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Expect the withdrawals to be made.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        expectTransferCall({ to: users.recipient, amount: withdrawAmount });
        expectTransferCall({ to: users.recipient, amount: withdrawAmount });

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount, "withdrawnAmount1");
    }

    modifier whenCallerRecipient() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SomeAmountsZero()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT, 0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_WithdrawAmountZero.selector, defaultStreamIds[1]));
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenAllAmountsNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SomeAmountsGreaterThanWithdrawableAmount()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
        whenAllAmountsNotZero
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(defaultStreamIds[1]);
        uint128[] memory amounts = Solarray.uint128s(withdrawableAmount, UINT128_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamIds[1],
                UINT128_MAX,
                withdrawableAmount
            )
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenAllAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, and mark the streams as
    /// depleted.
    function test_WithdrawMultiple_AllStreamsEnded()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
        whenAllAmountsNotZero
        whenAllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp into the future, past the end time.
        vm.warp({ timestamp: DEFAULT_END_TIME });

        // Make Alice the `to` address in this test.
        address to = users.alice;

        // Expect two {WithdrawFromLockupStream} events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[0], to: to, amount: DEFAULT_DEPOSIT_AMOUNT });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[1], to: to, amount: DEFAULT_DEPOSIT_AMOUNT });

        // Expect the withdrawals to be made.
        expectTransferCall({ to: to, amount: DEFAULT_DEPOSIT_AMOUNT });
        expectTransferCall({ to: to, amount: DEFAULT_DEPOSIT_AMOUNT });

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_DEPOSIT_AMOUNT, DEFAULT_DEPOSIT_AMOUNT);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the streams have been marked as depleted.
        Lockup.Status actualStatus0 = lockup.getStatus(defaultStreamIds[0]);
        Lockup.Status actualStatus1 = lockup.getStatus(defaultStreamIds[1]);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = DEFAULT_DEPOSIT_AMOUNT;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount, "withdrawnAmount1");

        // Assert that the NFTs have not been burned.
        address actualNFTOwner0 = lockup.ownerOf(defaultStreamIds[0]);
        address actualNFTOwner1 = lockup.ownerOf(defaultStreamIds[1]);
        address actualNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, actualNFTOwner, "NFT owner0");
        assertEq(actualNFTOwner1, actualNFTOwner, "NFT owner1");
    }

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, and update the
    /// withdrawn
    /// amounts.
    function test_WithdrawMultiple_AllStreamsOngoing()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
        whenAllAmountsNotZero
        whenAllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp into the future, before the end time of the streams.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make Alice the `to` address in this test.
        address to = users.alice;

        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.streamedAmountOf(defaultStreamIds[0]);

        // Expect the withdrawals to be made.
        expectTransferCall({ to: to, amount: withdrawAmount });
        expectTransferCall({ to: to, amount: withdrawAmount });

        // Expect two {WithdrawFromLockupStream} events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[0], to: to, amount: withdrawAmount });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[1], to: to, amount: withdrawAmount });

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(withdrawAmount, withdrawAmount);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the streams have remained active.
        Lockup.Status actualStatus0 = lockup.getStatus(defaultStreamIds[0]);
        Lockup.Status actualStatus1 = lockup.getStatus(defaultStreamIds[1]);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus0, expectedStatus, "status0");
        assertEq(actualStatus1, expectedStatus, "status1");

        // Assert that the withdrawn amounts have been updated.
        uint128 actualWithdrawnAmount0 = lockup.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = lockup.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount, "withdrawnAmount1");
    }

    struct Vars {
        address actualEndedNFTOwner;
        Lockup.Status actualStatus0;
        Lockup.Status actualStatus1;
        uint128 actualWithdrawnAmount0;
        uint128 actualWithdrawnAmount1;
        uint128[] amounts;
        uint256 endedStreamId;
        uint128 endedWithdrawAmount;
        address expectedEndedNFTOwner;
        Lockup.Status expectedStatus0;
        Lockup.Status expectedStatus1;
        uint128 expectedWithdrawnAmount0;
        uint128 expectedWithdrawnAmount1;
        uint40 ongoingEndTime;
        uint256 ongoingStreamId;
        uint128 ongoingWithdrawAmount;
        uint256[] streamIds;
        address to;
    }

    /// @dev it should make the withdrawals, emit multiple {WithdrawFromLockupStream} events, mark the ended streams
    /// as
    /// depleted, and update the withdrawn amounts.
    function test_WithdrawMultiple_SomeStreamsEndedSomeStreamsOngoing()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenOnlyNonNullStreams
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
        whenAllAmountsNotZero
        whenAllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_END_TIME });

        // Make Alice the `to` address in this test.
        Vars memory vars;
        vars.to = users.alice;

        // Use the first default stream as the ended stream.
        vars.endedStreamId = defaultStreamIds[0];
        vars.endedWithdrawAmount = DEFAULT_DEPOSIT_AMOUNT;

        // Create a new stream with an end time nearly double that of the default stream.
        vars.ongoingEndTime = DEFAULT_END_TIME + DEFAULT_TOTAL_DURATION;
        vars.ongoingStreamId = createDefaultStreamWithEndTime(vars.ongoingEndTime);

        // Get the ongoing withdraw amount.
        vars.ongoingWithdrawAmount = lockup.withdrawableAmountOf(vars.ongoingStreamId);

        // Expect two {WithdrawFromLockupStream} events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: vars.endedStreamId, to: vars.to, amount: vars.endedWithdrawAmount });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: vars.ongoingStreamId, to: vars.to, amount: vars.ongoingWithdrawAmount });

        // Run the test.
        vars.streamIds = Solarray.uint256s(vars.endedStreamId, vars.ongoingStreamId);
        vars.amounts = Solarray.uint128s(vars.endedWithdrawAmount, vars.ongoingWithdrawAmount);
        lockup.withdrawMultiple({ streamIds: vars.streamIds, to: vars.to, amounts: vars.amounts });

        // Assert that the ended stream has been marked as depleted, and the ongoing stream has not been.
        vars.actualStatus0 = lockup.getStatus(vars.endedStreamId);
        vars.actualStatus1 = lockup.getStatus(vars.ongoingStreamId);
        vars.expectedStatus0 = Lockup.Status.DEPLETED;
        vars.expectedStatus1 = Lockup.Status.ACTIVE;
        assertEq(vars.actualStatus0, vars.expectedStatus0, "status0");
        assertEq(vars.actualStatus1, vars.expectedStatus1, "status1");

        // Assert that the withdrawn amounts amounts have been updated.
        vars.actualWithdrawnAmount0 = lockup.getWithdrawnAmount(vars.endedStreamId);
        vars.actualWithdrawnAmount1 = lockup.getWithdrawnAmount(vars.ongoingStreamId);
        vars.expectedWithdrawnAmount0 = vars.endedWithdrawAmount;
        vars.expectedWithdrawnAmount1 = vars.ongoingWithdrawAmount;
        assertEq(vars.actualWithdrawnAmount0, vars.expectedWithdrawnAmount0, "withdrawnAmount0");
        assertEq(vars.actualWithdrawnAmount1, vars.expectedWithdrawnAmount1, "withdrawnAmount1");

        // Assert that the ended stream NFT has not been burned.
        vars.actualEndedNFTOwner = lockup.getRecipient(vars.endedStreamId);
        vars.expectedEndedNFTOwner = users.recipient;
        assertEq(vars.actualEndedNFTOwner, vars.expectedEndedNFTOwner, "NFT owner");
    }
}
