// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract WithdrawMultiple_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        // Define the default amounts, since most tests need them.
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    modifier whenArraysEqual() {
        _;
    }

    modifier whenAllStreamsEitherActiveOrCanceled() {
        _;
    }

    modifier whenCallerAuthorizedAllStreams() {
        _;
    }

    function testFuzz_WithdrawMultiple_CallerApprovedOperator(address to)
        external
        whenToNonZeroAddress
        whenArraysEqual
        whenAllStreamsEitherActiveOrCanceled
        whenCallerAuthorizedAllStreams
    {
        vm.assume(to != address(0));

        // Approve the operator for all streams.
        lockup.setApprovalForAll({ operator: users.operator, _approved: true });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Expect the withdrawals to be made.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        expectTransferCall({ to: to, amount: withdrawAmount });
        expectTransferCall({ to: to, amount: withdrawAmount });

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: defaultAmounts });

        // Assert that the withdrawn amounts have been updated.
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[0]), expectedWithdrawnAmount, "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[1]), expectedWithdrawnAmount, "withdrawnAmount1");
    }

    modifier whenCallerRecipient() {
        _;
    }

    modifier whenAllAmountsNotZero() {
        _;
    }

    modifier whenAllAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    function testFuzz_WithdrawMultiple(
        uint256 timeWarp,
        address to,
        uint128 ongoingWithdrawAmount
    )
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArraysEqual
        whenAllStreamsEitherActiveOrCanceled
        whenCallerAuthorizedAllStreams
        whenCallerRecipient
        whenAllAmountsNotZero
        whenAllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        vm.assume(to != address(0));
        timeWarp = bound(timeWarp, DEFAULT_TOTAL_DURATION, DEFAULT_TOTAL_DURATION * 2 - 1);

        // Create a new stream with an end time nearly double that of the default stream.
        uint40 ongoingEndTime = DEFAULT_END_TIME + DEFAULT_TOTAL_DURATION;
        uint256 ongoingStreamId = createDefaultStreamWithEndTime(ongoingEndTime);

        // Use a default stream as the settled stream.
        uint256 settledStreamId = defaultStreamIds[0];
        uint128 settledWithdrawAmount = DEFAULT_DEPOSIT_AMOUNT;

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the ongoing withdraw amount.
        uint128 ongoingWithdrawableAmount = lockup.withdrawableAmountOf(ongoingStreamId);
        ongoingWithdrawAmount = boundUint128(ongoingWithdrawAmount, 1, ongoingWithdrawableAmount);

        // Expect the {WithdrawFromLockupStream} events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: ongoingStreamId, to: to, amount: ongoingWithdrawAmount });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: settledStreamId, to: to, amount: settledWithdrawAmount });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(ongoingStreamId, settledStreamId);
        uint128[] memory amounts = Solarray.uint128s(ongoingWithdrawAmount, settledWithdrawAmount);
        lockup.withdrawMultiple({ streamIds: streamIds, to: to, amounts: amounts });

        // Assert that the settled stream has been marked as depleted, and the ongoing stream has not been.
        assertEq(lockup.getStatus(streamIds[0]), Lockup.Status.ACTIVE, "status0");
        assertEq(lockup.getStatus(streamIds[1]), Lockup.Status.DEPLETED, "status1");

        // Assert that the withdrawn amounts have been updated.
        assertEq(lockup.getWithdrawnAmount(streamIds[0]), amounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(streamIds[1]), amounts[1], "withdrawnAmount1");

        // Assert that the stream NFTs have not been burned.
        assertEq(lockup.getRecipient(streamIds[0]), users.recipient, "NFT owner0");
        assertEq(lockup.getRecipient(streamIds[1]), users.recipient, "NFT owner1");
    }
}
