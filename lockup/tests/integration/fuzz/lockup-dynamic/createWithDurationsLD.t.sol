// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupDynamic } from "src/interfaces/ISablierLockupDynamic.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupDynamic } from "src/types/LockupDynamic.sol";
import { Lockup_Dynamic_Integration_Fuzz_Test } from "./LockupDynamic.t.sol";

contract CreateWithDurationsLD_Integration_Fuzz_Test is Lockup_Dynamic_Integration_Fuzz_Test {
    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        Lockup.Status actualStatus;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        Lockup.Status expectedStatus;
        bool isCancelable;
        bool isSettled;
        LockupDynamic.Segment[] segmentsWithTimestamps;
        uint128 depositAmount;
    }

    function testFuzz_CreateWithDurationsLD(LockupDynamic.SegmentWithDuration[] memory segments)
        external
        whenNoDelegateCall
        whenTimestampsCalculationNotOverflow
    {
        vm.assume(segments.length != 0);

        // Fuzz the durations.
        Vars memory vars;
        fuzzSegmentDurations(segments);

        // Fuzz the segment amounts and calculate the deposit amount.
        vars.depositAmount = fuzzDynamicStreamAmounts(segments);

        uint256 expectedStreamId = lockup.nextStreamId();

        // Mint enough tokens to the sender.
        deal({ token: address(dai), to: users.sender, give: vars.depositAmount });

        // Expect the tokens to be transferred from the sender to {SablierLockup}.
        expectCallToTransferFrom({ from: users.sender, to: address(lockup), value: vars.depositAmount });

        // Create the timestamps struct.
        vars.segmentsWithTimestamps = getSegmentsWithTimestamps(segments);
        Lockup.Timestamps memory timestamps = Lockup.Timestamps({
            start: getBlockTimestamp(),
            end: vars.segmentsWithTimestamps[vars.segmentsWithTimestamps.length - 1].timestamp
        });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupDynamic.CreateLockupDynamicStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(vars.depositAmount, timestamps),
            segments: vars.segmentsWithTimestamps
        });

        // Create the stream.
        _defaultParams.createWithDurations.depositAmount = vars.depositAmount;
        _defaultParams.createWithDurations.transferable = true;
        uint256 streamId = lockup.createWithDurationsLD(_defaultParams.createWithDurations, segments);

        // Check if the stream is settled. It is possible for a stream to settle at the time of creation because some
        // segment amounts can be zero.
        vars.isSettled = lockup.refundableAmountOf(streamId) == 0;
        vars.isCancelable = vars.isSettled ? false : true;

        // It should create the stream.
        assertEq(lockup.getDepositedAmount(streamId), vars.depositAmount, "depositedAmount");
        assertEq(lockup.getEndTime(streamId), timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), vars.isCancelable, "isCancelable");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_DYNAMIC);
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getSegments(streamId), vars.segmentsWithTimestamps);
        assertEq(lockup.getStartTime(streamId), timestamps.start, "startTime");
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");

        // Assert that the stream's status is correct.
        vars.actualStatus = lockup.statusOf(streamId);
        vars.expectedStatus = vars.isSettled ? Lockup.Status.SETTLED : Lockup.Status.STREAMING;
        assertEq(vars.actualStatus, vars.expectedStatus);

        // Assert that the next stream ID has been bumped.
        vars.actualNextStreamId = lockup.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = users.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
