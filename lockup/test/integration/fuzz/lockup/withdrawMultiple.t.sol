// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { WithdrawMultiple_Integration_Shared_Test } from "../../shared/lockup/withdrawMultiple.t.sol";
import { Integration_Test } from "../../Integration.t.sol";

abstract contract WithdrawMultiple_Integration_Fuzz_Test is
    Integration_Test,
    WithdrawMultiple_Integration_Shared_Test
{
    function setUp() public virtual override(Integration_Test, WithdrawMultiple_Integration_Shared_Test) {
        WithdrawMultiple_Integration_Shared_Test.setUp();
    }

    function testFuzz_WithdrawMultiple(
        uint256 timeJump,
        address to,
        uint128 ongoingWithdrawAmount
    )
        external
        whenNotDelegateCalled
        whenArraysEqual
        whenNoNull
        whenNoDepletedStream
        whenCallerAuthorizedAllStreams
        whenToNonZeroAddress
        whenNoAmountZero
        whenNoAmountOverdraws
    {
        vm.assume(to != address(0));
        timeJump = _bound(timeJump, defaults.TOTAL_DURATION(), defaults.TOTAL_DURATION() * 2 - 1 seconds);

        // Hard code the withdrawal address if the caller is the stream's sender.
        if (caller == users.sender) {
            to = users.recipient;
        }

        // Create a new stream with an end time double that of the default stream.
        changePrank({ msgSender: users.sender });
        uint40 ongoingEndTime = defaults.END_TIME() + defaults.TOTAL_DURATION();
        uint256 ongoingStreamId = createDefaultStreamWithEndTime(ongoingEndTime);

        // Create and use a default stream as the settled stream.
        uint256 settledStreamId = createDefaultStream();
        uint128 settledWithdrawAmount = defaults.DEPOSIT_AMOUNT();

        // Run the test with the caller provided in {whenCallerAuthorizedAllStreams}.
        changePrank({ msgSender: caller });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.START_TIME() + timeJump });

        // Bound the ongoing withdraw amount.
        uint128 ongoingWithdrawableAmount = lockup.withdrawableAmountOf(ongoingStreamId);
        ongoingWithdrawAmount = boundUint128(ongoingWithdrawAmount, 1, ongoingWithdrawableAmount);

        // Expect the withdrawals to be made.
        expectCallToTransfer({ to: to, amount: ongoingWithdrawAmount });
        expectCallToTransfer({ to: to, amount: settledWithdrawAmount });

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: ongoingStreamId, to: to, amount: ongoingWithdrawAmount });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: settledStreamId, to: to, amount: settledWithdrawAmount });

        // Make the withdrawals.
        uint256[] memory streamIds = Solarray.uint256s(ongoingStreamId, settledStreamId);
        uint128[] memory amounts = Solarray.uint128s(ongoingWithdrawAmount, settledWithdrawAmount);
        lockup.withdrawMultiple({ streamIds: streamIds, to: to, amounts: amounts });

        // Assert that the statuses have been updated.
        assertEq(lockup.statusOf(streamIds[0]), Lockup.Status.STREAMING, "status0");
        assertEq(lockup.statusOf(streamIds[1]), Lockup.Status.DEPLETED, "status1");

        // Assert that the withdrawn amounts have been updated.
        assertEq(lockup.getWithdrawnAmount(streamIds[0]), amounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(streamIds[1]), amounts[1], "withdrawnAmount1");

        // Assert that the stream NFTs have not been burned.
        assertEq(lockup.getRecipient(streamIds[0]), users.recipient, "NFT owner0");
        assertEq(lockup.getRecipient(streamIds[1]), users.recipient, "NFT owner1");
    }
}
