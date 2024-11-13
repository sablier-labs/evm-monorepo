// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup, LockupDynamic } from "src/core/types/DataTypes.sol";

import { Lockup_Dynamic_Integration_Shared_Test } from "./../LockupDynamic.t.sol";

contract CreateWithDurationsLD_Integration_Concrete_Test is Lockup_Dynamic_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Lockup_Dynamic_Integration_Shared_Test.setUp();
        streamId = lockup.nextStreamId();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(
            ISablierLockup.createWithDurationsLD, (defaults.createWithDurations(), defaults.segmentsWithDurations())
        );
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_SegmentCountExceedsMaxValue() external whenNoDelegateCall {
        LockupDynamic.SegmentWithDuration[] memory segments = new LockupDynamic.SegmentWithDuration[](25_000);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_SegmentCountTooHigh.selector, 25_000));
        createDefaultStreamWithDurationsLD(segments);
    }

    function test_RevertWhen_FirstIndexHasZeroDuration()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
    {
        uint40 startTime = getBlockTimestamp();
        LockupDynamic.SegmentWithDuration[] memory segments = defaults.segmentsWithDurations();
        segments[1].duration = 0;
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_SegmentTimestampsNotOrdered.selector,
                index,
                startTime + segments[0].duration,
                startTime + segments[0].duration
            )
        );
        createDefaultStreamWithDurationsLD(segments);
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
            LockupDynamic.SegmentWithDuration[] memory segments = defaults.segmentsWithDurations();
            segments[0].duration = MAX_UINT40;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierLockup_StartTimeNotLessThanFirstSegmentTimestamp.selector,
                    startTime,
                    startTime + segments[0].duration
                )
            );
            createDefaultStreamWithDurationsLD(segments);
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
            LockupDynamic.SegmentWithDuration[] memory segments = new LockupDynamic.SegmentWithDuration[](2);
            segments[0] = LockupDynamic.SegmentWithDuration({
                amount: 0,
                exponent: ud2x18(1e18),
                duration: startTime + 1 seconds
            });
            segments[1] = defaults.segmentsWithDurations()[0];
            segments[1].duration = MAX_UINT40;

            // Expect the relevant error to be thrown.
            uint256 index = 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierLockup_SegmentTimestampsNotOrdered.selector,
                    index,
                    startTime + segments[0].duration,
                    startTime + segments[0].duration + segments[1].duration
                )
            );

            // Create the stream.
            createDefaultStreamWithDurationsLD(segments);
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

        // Declare the timestamps.
        uint40 blockTimestamp = getBlockTimestamp();
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: blockTimestamp, cliff: 0, end: blockTimestamp + defaults.TOTAL_DURATION() });

        // Adjust the segments.
        LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations = defaults.segmentsWithDurations();
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].timestamp = timestamps.start + segmentsWithDurations[0].duration;
        segments[1].timestamp = segments[0].timestamp + segmentsWithDurations[1].duration;

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ from: funder, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, value: defaults.BROKER_FEE_AMOUNT() });

        // It should emit {CreateLockupDynamicStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupDynamicStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: dai,
            cancelable: true,
            transferable: true,
            segments: segments,
            timestamps: timestamps,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDurationsLD();

        // Assert that the stream has been created.
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getAsset(streamId), dai, "asset");
        assertEq(lockup.getEndTime(streamId), timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertEq(lockup.isDepleted(streamId), false, "isDepleted");
        assertEq(lockup.isStream(streamId), true, "isStream");
        assertEq(lockup.isTransferable(streamId), true, "isTransferable");
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), timestamps.start, "startTime");
        assertEq(lockup.wasCanceled(streamId), false, "wasCanceled");
        assertEq(lockup.getSegments(streamId), segments, "segments");

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
