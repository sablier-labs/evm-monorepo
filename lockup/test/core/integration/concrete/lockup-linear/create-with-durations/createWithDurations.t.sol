// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupLinear } from "src/core/interfaces/ISablierLockupLinear.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup, LockupLinear } from "src/core/types/DataTypes.sol";

import { CreateWithDurations_Integration_Shared_Test } from "../../../shared/lockup/createWithDurations.t.sol";
import { LockupLinear_Integration_Concrete_Test } from "../LockupLinear.t.sol";

contract CreateWithDurations_LockupLinear_Integration_Concrete_Test is
    LockupLinear_Integration_Concrete_Test,
    CreateWithDurations_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Concrete_Test, CreateWithDurations_Integration_Shared_Test)
    {
        LockupLinear_Integration_Concrete_Test.setUp();
        CreateWithDurations_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierLockupLinear.createWithDurations, defaults.createWithDurationsLL());
        (bool success, bytes memory returnData) = address(lockupLinear).delegatecall(callData);
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
            abi.encodeWithSelector(
                Errors.SablierLockupLinear_StartTimeNotLessThanCliffTime.selector, startTime, cliffTime
            )
        );

        // Create the stream.
        createDefaultStreamWithDurations(LockupLinear.Durations({ cliff: cliffDuration, total: totalDuration }));
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
            abi.encodeWithSelector(Errors.SablierLockupLinear_StartTimeNotLessThanEndTime.selector, startTime, endTime)
        );

        // Create the stream.
        createDefaultStreamWithDurations(durations);
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
        LockupLinear.Timestamps memory timestamps = LockupLinear.Timestamps({
            start: blockTimestamp,
            cliff: blockTimestamp + durations.cliff,
            end: blockTimestamp + durations.total
        });

        if (durations.cliff == 0) timestamps.cliff = 0;

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ from: funder, to: address(lockupLinear), value: defaults.DEPOSIT_AMOUNT() });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, value: defaults.BROKER_FEE_AMOUNT() });

        // It should emit {CreateLockupLinearStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockupLinear) });
        emit MetadataUpdate({ _tokenId: streamId });
        vm.expectEmit({ emitter: address(lockupLinear) });
        emit CreateLockupLinearStream({
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
        createDefaultStreamWithDurations(durations);

        // It should create the stream.
        LockupLinear.StreamLL memory actualStream = lockupLinear.getStream(streamId);
        LockupLinear.StreamLL memory expectedStream = defaults.lockupLinearStream();
        expectedStream.startTime = timestamps.start;
        expectedStream.cliffTime = timestamps.cliff;
        expectedStream.endTime = timestamps.end;
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = lockupLinear.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should bump the next stream ID.
        uint256 actualNextStreamId = lockupLinear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // It should mint the NFT.
        address actualNFTOwner = lockupLinear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
