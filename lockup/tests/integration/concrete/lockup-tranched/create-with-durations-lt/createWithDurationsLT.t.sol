// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockupTranched } from "src/interfaces/ISablierLockupTranched.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupTranched } from "src/types/LockupTranched.sol";

import { Lockup_Tranched_Integration_Concrete_Test } from "./../LockupTranched.t.sol";

contract CreateWithDurationsLT_Integration_Concrete_Test is Lockup_Tranched_Integration_Concrete_Test {
    function setUp() public virtual override {
        Lockup_Tranched_Integration_Concrete_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev We need this function as we cannot copy from memory to storage.
    function createDefaultStreamWithDurations(LockupTranched.TrancheWithDuration[] memory tranchesWithDurations)
        internal
        returns (uint256 streamId)
    {
        streamId = lockup.createWithDurationsLT(_defaultParams.createWithDurations, tranchesWithDurations);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({
            callData: abi.encodeCall(
                lockup.createWithDurationsLT, (defaults.createWithDurations(), defaults.tranchesWithDurations())
            )
        });
    }

    function test_RevertWhen_FirstIndexHasZeroDuration() external whenNoDelegateCall {
        uint40 startTime = getBlockTimestamp();
        LockupTranched.TrancheWithDuration[] memory tranches = defaults.tranchesWithDurations();
        uint256 index = 1;
        tranches[index].duration = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_TrancheTimestampsNotOrdered.selector,
                index,
                startTime + tranches[0].duration,
                startTime + tranches[0].duration
            )
        );
        createDefaultStreamWithDurations(tranches);
    }

    function test_RevertWhen_StartTimeExceedsFirstTimestamp()
        external
        whenNoDelegateCall
        whenFirstIndexHasNonZeroDuration
        whenTimestampsCalculationOverflows
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();
            LockupTranched.TrancheWithDuration[] memory tranches = defaults.tranchesWithDurations();
            tranches[0].duration = MAX_UINT40;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierHelpers_StartTimeNotLessThanFirstTrancheTimestamp.selector,
                    startTime,
                    startTime + tranches[0].duration
                )
            );
            createDefaultStreamWithDurations(tranches);
        }
    }

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenFirstIndexHasNonZeroDuration
        whenTimestampsCalculationOverflows
        whenStartTimeNotExceedsFirstTimestamp
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();

            // Create new tranches that overflow when the timestamps are eventually calculated.
            LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](2);
            tranches[0] = LockupTranched.TrancheWithDuration({ amount: 0, duration: startTime + 1 seconds });
            tranches[1] = defaults.tranchesWithDurations()[0];
            tranches[1].duration = MAX_UINT40;

            // Expect the relevant error to be thrown.
            uint256 index = 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierHelpers_TrancheTimestampsNotOrdered.selector,
                    index,
                    startTime + tranches[0].duration,
                    startTime + tranches[0].duration + tranches[1].duration
                )
            );

            createDefaultStreamWithDurations(tranches);
        }
    }

    function test_WhenTimestampsCalculationNotOverflow() external whenNoDelegateCall whenFirstIndexHasNonZeroDuration {
        uint256 expectedStreamId = lockup.nextStreamId();

        // Declare the timestamps.
        uint40 blockTimestamp = getBlockTimestamp();
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: blockTimestamp, end: blockTimestamp + defaults.TOTAL_DURATION() });

        LockupTranched.TrancheWithDuration[] memory tranchesWithDurations = defaults.tranchesWithDurations();
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        tranches[0].timestamp = timestamps.start + tranchesWithDurations[0].duration;
        tranches[1].timestamp = tranches[0].timestamp + tranchesWithDurations[1].duration;

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ from: users.sender, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // It should emit {MetadataUpdate} and {CreateLockupTranchedStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupTranched.CreateLockupTranchedStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(timestamps),
            tranches: tranches
        });

        // Create the stream.
        uint256 streamId = createDefaultStreamWithDurations(tranchesWithDurations);

        // Assert that the stream has been created.
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getEndTime(streamId), timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_TRANCHED);
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), timestamps.start, "startTime");
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");

        assertEq(lockup.getTranches(streamId), tranches);

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
