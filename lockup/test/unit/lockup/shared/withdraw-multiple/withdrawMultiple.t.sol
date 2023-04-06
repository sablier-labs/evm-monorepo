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
        defaultAmounts.push(DEFAULT_DEPOSIT_AMOUNT);

        // Create three streams: a default stream, a stream meant to be canceled, and a stream with an early end time.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStreamWithEndTime(WARP_TIME_26));

        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2Lockup.withdrawMultiple, (defaultStreamIds, users.recipient, defaultAmounts));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_RevertWhen_ZeroAddress() external whenNoDelegateCall {
        vm.expectRevert(Errors.SablierV2Lockup_WithdrawToZeroAddress.selector);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: address(0), amounts: defaultAmounts });
    }

    modifier whenToNonZeroAddress() {
        _;
    }

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

    function test_WithdrawMultiple_ArrayCountsZero() external whenNoDelegateCall whenToNonZeroAddress {
        uint256[] memory streamIds = new uint256[](0);
        uint128[] memory amounts = new uint128[](0);
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenArrayCountsNotZero() {
        _;
    }

    function test_RevertWhen_AllStreamsEitherNullOrDepleted()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
    {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        lockup.withdrawMultiple({
            streamIds: Solarray.uint256s(nullStreamId),
            to: users.recipient,
            amounts: Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT)
        });
    }

    function test_RevertWhen_SomeStreamsEitherNullOrDepleted()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
    {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], defaultStreamIds[1], nullStreamId);

        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Expect a {SablierV2Lockup_StreamNull} error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier whenAllStreamsNeitherNullNorDepleted() {
        _;
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_Sender()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
    {
        // Make the sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.sender)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.sender, amounts: defaultAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
    {
        // Transfer all streams to Alice.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[2] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
    {
        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = createDefaultStreamWithRecipient(users.eve);

        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0], defaultStreamIds[1]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
    {
        // Transfer one of the streams to Eve.
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier whenCallerAuthorizedAllStreams() {
        _;
    }

    function test_WithdrawMultiple_CallerApprovedOperator()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
        whenCallerAuthorizedAllStreams
    {
        // Approve the operator for all streams.
        lockup.setApprovalForAll({ operator: users.operator, _approved: true });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Expect the withdrawals to be made.
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[0] });
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[1] });
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[2] });

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });

        // Assert that the withdrawn amounts have been updated.
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[0]), defaultAmounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[1]), defaultAmounts[1], "withdrawnAmount1");
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[2]), defaultAmounts[2], "withdrawnAmount2");
    }

    modifier whenCallerRecipient() {
        _;
    }

    function test_RevertWhen_SomeAmountsZero()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
    {
        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Run the test.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT, 0, 0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_WithdrawAmountZero.selector, defaultStreamIds[1]));
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenAllAmountsNotZero() {
        _;
    }

    function test_RevertWhen_SomeAmountsGreaterThanWithdrawableAmount()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
        whenAllAmountsNotZero
    {
        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Run the test.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(defaultStreamIds[2]);
        uint128[] memory amounts = Solarray.uint128s(defaultAmounts[0], defaultAmounts[1], UINT128_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamIds[2],
                UINT128_MAX,
                withdrawableAmount
            )
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenAllAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    function test_WithdrawMultiple()
        internal
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsNotEqual
        whenArrayCountsNotZero
        whenAllStreamsNeitherNullNorDepleted
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
        whenAllAmountsNotZero
        whenAllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Cancel the second stream.
        lockup.cancel(defaultStreamIds[1]);

        // Expect the withdrawals to be made.
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[0] });
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[1] });
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[2] });

        // Expect the {WithdrawFromLockupStream} events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[0], to: users.alice, amount: defaultAmounts[0] });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[1], to: users.alice, amount: defaultAmounts[1] });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[2], to: users.alice, amount: defaultAmounts[2] });

        // Run the test.
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.alice, amounts: defaultAmounts });

        // Assert that the statuses have been updated.
        assertEq(lockup.getStatus(defaultStreamIds[0]), Lockup.Status.ACTIVE, "status0");
        assertEq(lockup.getStatus(defaultStreamIds[1]), Lockup.Status.DEPLETED, "status0");
        assertEq(lockup.getStatus(defaultStreamIds[2]), Lockup.Status.DEPLETED, "status0");

        // Assert that the withdrawn amounts have been updated.
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[0]), defaultAmounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[1]), defaultAmounts[1], "withdrawnAmount1");
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[2]), defaultAmounts[2], "withdrawnAmount2");

        // Assert that the stream NFTs have not been burned.
        assertEq(lockup.getRecipient(defaultStreamIds[0]), users.recipient, "NFT owner0");
        assertEq(lockup.getRecipient(defaultStreamIds[1]), users.recipient, "NFT owner1");
        assertEq(lockup.getRecipient(defaultStreamIds[2]), users.recipient, "NFT owner2");
    }
}
