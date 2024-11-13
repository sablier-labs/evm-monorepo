// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup, LockupLinear } from "src/core/types/DataTypes.sol";

import { Lockup_Linear_Integration_Fuzz_Test } from "./LockupLinear.t.sol";

contract CreateWithDurationsLL_Integration_Fuzz_Test is Lockup_Linear_Integration_Fuzz_Test {
    function testFuzz_RevertWhen_TotalDurationCalculationOverflows(LockupLinear.Durations memory durations)
        external
        whenNoDelegateCall
        WhenCliffTimeCalculationNotOverflow
    {
        uint40 startTime = getBlockTimestamp();
        durations.cliff = boundUint40(durations.cliff, 1 seconds, MAX_UINT40 - startTime);
        durations.total = boundUint40(durations.total, MAX_UINT40 - startTime + 1 seconds, MAX_UINT40);

        // Calculate the cliff time and the end time. Needs to be "unchecked" to allow an overflow.
        uint40 cliffTime;
        uint40 endTime;
        unchecked {
            cliffTime = startTime + durations.cliff;
            endTime = startTime + durations.total;
        }

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_CliffTimeNotLessThanEndTime.selector, cliffTime, endTime)
        );

        // Create the stream.
        _defaultParams.durations = durations;
        createDefaultStreamWithDurations();
    }

    function testFuzz_CreateWithDurationsLL(LockupLinear.Durations memory durations)
        external
        whenNoDelegateCall
        WhenCliffTimeCalculationNotOverflow
        whenEndTimeCalculationNotOverflow
    {
        durations.total = boundUint40(durations.total, 1 seconds, MAX_UNIX_TIMESTAMP);
        vm.assume(durations.cliff < durations.total);

        // Make the Sender the stream's funder (recall that the Sender is the default caller).
        address funder = users.sender;
        uint256 expectedStreamId = lockup.nextStreamId();

        // Expect the assets to be transferred from the funder to {SablierLockup}.
        expectCallToTransferFrom({ from: funder, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, value: defaults.BROKER_FEE_AMOUNT() });

        // Create the timestamps struct by calculating the start time, cliff time and the end time.
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: getBlockTimestamp(), end: getBlockTimestamp() + durations.total });

        uint40 cliffTime;
        if (durations.cliff > 0) {
            cliffTime = getBlockTimestamp() + durations.cliff;
        }

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: expectedStreamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: dai,
            cancelable: true,
            transferable: true,
            timestamps: timestamps,
            cliffTime: cliffTime,
            broker: users.broker
        });

        // Create the stream.
        _defaultParams.durations = durations;
        uint256 streamId = createDefaultStreamWithDurations();

        // It should create the stream.
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getAsset(streamId), dai, "asset");
        assertEq(lockup.getEndTime(streamId), timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), timestamps.start, "startTime");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");
        assertEq(lockup.getCliffTime(streamId), cliffTime, "cliffTime");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_LINEAR);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the next stream ID has been bumped.
        uint256 actualNextStreamId = lockup.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");
    }
}
