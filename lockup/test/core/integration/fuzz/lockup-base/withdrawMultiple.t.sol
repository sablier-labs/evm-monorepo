// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Solarray } from "solarray/src/Solarray.sol";
import { ISablierLockupBase } from "src/core/interfaces/ISablierLockupBase.sol";
import { Lockup } from "src/core/types/DataTypes.sol";

import { Lockup_Integration_Shared_Test } from "../../shared/lockup/Lockup.t.sol";

abstract contract WithdrawMultiple_Integration_Fuzz_Test is Lockup_Integration_Shared_Test {
    address internal caller;
    Lockup.Model internal lockupModel;
    // The original time when the tests started.
    uint40 internal originalTime;

    function setUp() public virtual override {
        Lockup_Integration_Shared_Test.setUp();
        originalTime = getBlockTimestamp();
    }

    function testFuzz_WithdrawMultiple(
        uint256 timeJump,
        uint128 ongoingWithdrawAmount
    )
        external
        whenNoDelegateCall
        whenArraysEqual
        givenNotNull
        givenNoDEPLETEDStreams
        whenCallerAuthorizedForAllStreams
        whenWithdrawalAddressNotZero
        whenNoZeroAmounts
        whenNoAmountOverdraws
    {
        timeJump = _bound(timeJump, defaults.TOTAL_DURATION(), defaults.TOTAL_DURATION() * 2 - 1 seconds);

        // Create a new stream with an end time double that of the default stream.
        uint40 ongoingEndTime = defaults.END_TIME() + defaults.TOTAL_DURATION();

        // Create a new stream with ongoing end time.
        uint256 ongoingStreamId;
        if (lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            ongoingStreamId = createDefaultStreamWithEndTimeLL(ongoingEndTime);
        } else if (lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            ongoingStreamId = createDefaultStreamWithEndTimeLD(ongoingEndTime);
        } else if (lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            ongoingStreamId = createDefaultStreamWithEndTimeLT(ongoingEndTime);
        }

        // Create and use a default stream as the settled stream.
        uint256 settledStreamId = createDefaultStreamLD();
        uint128 settledWithdrawAmount = defaults.DEPOSIT_AMOUNT();

        // Run the test with the caller provided in {whenCallerAuthorizedForAllStreams}.
        resetPrank({ msgSender: caller });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Bound the ongoing withdraw amount.
        uint128 ongoingWithdrawableAmount = lockup.withdrawableAmountOf(ongoingStreamId);
        ongoingWithdrawAmount = boundUint128(ongoingWithdrawAmount, 1, ongoingWithdrawableAmount);

        // Expect the withdrawals to be made.
        expectCallToTransfer({ to: users.recipient, value: ongoingWithdrawAmount });
        expectCallToTransfer({ to: users.recipient, value: settledWithdrawAmount });

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.WithdrawFromLockupStream({
            streamId: ongoingStreamId,
            to: users.recipient,
            asset: dai,
            amount: ongoingWithdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.WithdrawFromLockupStream({
            streamId: settledStreamId,
            to: users.recipient,
            asset: dai,
            amount: settledWithdrawAmount
        });

        // Make the withdrawals.
        uint256[] memory streamIds = Solarray.uint256s(ongoingStreamId, settledStreamId);
        uint128[] memory amounts = Solarray.uint128s(ongoingWithdrawAmount, settledWithdrawAmount);
        lockup.withdrawMultiple(streamIds, amounts);

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
