// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup, LockupLinear } from "src/core/types/DataTypes.sol";

import { Lockup_Linear_Integration_Shared_Test } from "../LockupLinear.t.sol";

contract CreateWithDurationsLL_Integration_Concrete_Test is Lockup_Linear_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Lockup_Linear_Integration_Shared_Test.setUp();
        streamId = lockup.nextStreamId();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierLockup.createWithDurationsLL, (defaults.createWithDurations(), defaults.durations()));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_CliffTimeCalculationOverflows() external whenNoDelegateCall whenCliffDurationNotZero {
        uint40 startTime = getBlockTimestamp();
        uint40 cliffDuration = MAX_UINT40 - startTime + 2 seconds;
        uint40 totalDuration = defaults.TOTAL_DURATION();

        // Calculate the end time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
        }

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_StartTimeNotLessThanCliffTime.selector, startTime, cliffTime)
        );

        // Create the stream.
        createDefaultStreamWithDurationsLL(LockupLinear.Durations({ cliff: cliffDuration, total: totalDuration }));
    }

    function test_WhenCliffTimeCalculationNotOverflow() external whenNoDelegateCall whenCliffDurationNotZero {
        LockupLinear.Durations memory durations = defaults.durations();
        _test_CreateWithDurations(durations);
    }

    function test_RevertWhen_EndTimeCalculationOverflows() external whenNoDelegateCall whenCliffDurationZero {
        uint40 startTime = getBlockTimestamp();
        LockupLinear.Durations memory durations =
            LockupLinear.Durations({ cliff: 0, total: MAX_UINT40 - startTime + 1 seconds });

        // Calculate the cliff time and the end time. Needs to be "unchecked" to allow an overflow.
        uint40 cliffTime;
        uint40 endTime;
        unchecked {
            cliffTime = startTime + durations.cliff;
            endTime = startTime + durations.total;
        }

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_StartTimeNotLessThanEndTime.selector, startTime, endTime)
        );

        // Create the stream.
        createDefaultStreamWithDurationsLL(durations);
    }

    function test_WhenEndTimeCalculationNotOverflow() external whenNoDelegateCall whenCliffDurationZero {
        LockupLinear.Durations memory durations = defaults.durations();
        durations.cliff = 0;
        _test_CreateWithDurations(durations);
    }

    function _test_CreateWithDurations(LockupLinear.Durations memory durations) private {
        // Make the Sender the stream's funder
        address funder = users.sender;

        // Declare the timestamps.
        uint40 blockTimestamp = getBlockTimestamp();
        Lockup.Timestamps memory timestamps = Lockup.Timestamps({
            start: blockTimestamp,
            cliff: blockTimestamp + durations.cliff,
            end: blockTimestamp + durations.total
        });

        if (durations.cliff == 0) timestamps.cliff = 0;

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ from: funder, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, value: defaults.BROKER_FEE_AMOUNT() });

        // It should emit {CreateLockupLinearStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: dai,
            cancelable: true,
            transferable: true,
            timestamps: timestamps,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDurationsLL(durations);

        // It should create the stream.
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
        assertEq(lockup.getCliffTime(streamId), timestamps.cliff, "cliff");

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
