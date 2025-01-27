// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Lockup_Dynamic_Integration_Concrete_Test } from "../LockupDynamic.t.sol";

contract CreateWithDurationsLD_Integration_Concrete_Test is Lockup_Dynamic_Integration_Concrete_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                       HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev We need this function as we cannot copy from memory to storage.
    function createDefaultStreamWithDurations(LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations)
        internal
        returns (uint256 streamId)
    {
        streamId = lockup.createWithDurationsLD(_defaultParams.createWithDurations, segmentsWithDurations);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({
            callData: abi.encodeCall(
                lockup.createWithDurationsLD, (defaults.createWithDurations(), defaults.segmentsWithDurations())
            )
        });
    }

    function test_RevertWhen_SegmentCountExceedsMaxValue() external whenNoDelegateCall {
        LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations =
            new LockupDynamic.SegmentWithDuration[](25_000);

        // Set the default segments with duration.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierHelpers_SegmentCountTooHigh.selector, 25_000));
        createDefaultStreamWithDurations(segmentsWithDurations);
    }

    function test_RevertWhen_FirstIndexHasZeroDuration()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
    {
        uint40 startTime = getBlockTimestamp();
        LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations = _defaultParams.segmentsWithDurations;
        segmentsWithDurations[1].duration = 0;

        // Set the default segments with duration.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_SegmentTimestampsNotOrdered.selector,
                index,
                startTime + segmentsWithDurations[0].duration,
                startTime + segmentsWithDurations[0].duration
            )
        );
        createDefaultStreamWithDurations(segmentsWithDurations);
    }

    function test_RevertWhen_StartTimeExceedsFirstTimestamp()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
        whenTimestampsCalculationOverflows
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();
            LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations = defaults.segmentsWithDurations();
            segmentsWithDurations[0].duration = MAX_UINT40;

            // Set the default segments with duration.
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierHelpers_StartTimeNotLessThanFirstSegmentTimestamp.selector,
                    startTime,
                    startTime + segmentsWithDurations[0].duration
                )
            );
            createDefaultStreamWithDurations(segmentsWithDurations);
        }
    }

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
        whenTimestampsCalculationOverflows
        whenStartTimeNotExceedsFirstTimestamp
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();

            // Create new segments that overflow when the timestamps are eventually calculated.
            LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations =
                new LockupDynamic.SegmentWithDuration[](2);
            segmentsWithDurations[0] = LockupDynamic.SegmentWithDuration({
                amount: 0,
                exponent: ud2x18(1e18),
                duration: startTime + 1 seconds
            });
            segmentsWithDurations[1] = defaults.segmentsWithDurations()[0];
            segmentsWithDurations[1].duration = MAX_UINT40;

            // Expect the relevant error to be thrown.
            uint256 index = 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierHelpers_SegmentTimestampsNotOrdered.selector,
                    index,
                    startTime + segmentsWithDurations[0].duration,
                    startTime + segmentsWithDurations[0].duration + segmentsWithDurations[1].duration
                )
            );
            createDefaultStreamWithDurations(segmentsWithDurations);
        }
    }

    function test_WhenTimestampsCalculationNotOverflow()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
    {
        // Make the Sender the stream's funder
        address funder = users.sender;
        uint256 expectedStreamId = lockup.nextStreamId();

        // Declare the timestamps.
        uint40 blockTimestamp = getBlockTimestamp();
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: blockTimestamp, end: blockTimestamp + defaults.TOTAL_DURATION() });

        // Adjust the segments.
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].timestamp = timestamps.start + _defaultParams.segmentsWithDurations[0].duration;
        segments[1].timestamp = segments[0].timestamp + _defaultParams.segmentsWithDurations[1].duration;

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ from: funder, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, value: defaults.BROKER_FEE_AMOUNT() });

        // It should emit {CreateLockupDynamicStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupDynamicStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(timestamps),
            segments: segments
        });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithDurations();

        // Assert that the stream has been created.
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getEndTime(streamId), timestamps.end, "endTime");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isCancelable(streamId), "isCancelable");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_DYNAMIC);
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), timestamps.start, "startTime");
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should bump the next stream ID.
        uint256 actualNextStreamId = lockup.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // It should mint the NFT.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
