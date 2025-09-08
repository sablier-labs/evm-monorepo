// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupLinear } from "src/interfaces/ISablierLockupLinear.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupLinear } from "src/types/LockupLinear.sol";

import { Lockup_Linear_Integration_Fuzz_Test } from "./LockupLinear.t.sol";

contract CreateWithDurationsLL_Integration_Fuzz_Test is Lockup_Linear_Integration_Fuzz_Test {
    function testFuzz_CreateWithDurationsLL(LockupLinear.Durations memory durations) external whenNoDelegateCall {
        durations.total = boundUint40(durations.total, 1 seconds, MAX_UNIX_TIMESTAMP);
        vm.assume(durations.cliff < durations.total);

        uint256 expectedStreamId = lockup.nextStreamId();

        // Expect the tokens to be transferred from the sender to {SablierLockup}.
        expectCallToTransferFrom({ from: users.sender, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // Create the timestamps struct by calculating the start time, cliff time and the end time.
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: getBlockTimestamp(), end: getBlockTimestamp() + durations.total });
        uint40 cliffTime = durations.cliff == 0 ? 0 : getBlockTimestamp() + durations.cliff;
        LockupLinear.UnlockAmounts memory unlockAmounts = defaults.unlockAmounts();
        unlockAmounts.cliff = durations.cliff > 0 ? unlockAmounts.cliff : 0;

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupLinear.CreateLockupLinearStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(timestamps),
            cliffTime: cliffTime,
            unlockAmounts: unlockAmounts
        });

        // Create the stream.
        _defaultParams.durations = durations;
        _defaultParams.unlockAmounts = unlockAmounts;
        uint256 streamId = createDefaultStreamWithDurations();

        // It should create the stream.
        assertEq(lockup.getCliffTime(streamId), cliffTime, "cliffTime");
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getEndTime(streamId), timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_LINEAR);
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), timestamps.start, "startTime");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");
        assertEq(lockup.getUnlockAmounts(streamId), unlockAmounts);

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
