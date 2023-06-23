// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { CreateWithDurations_Integration_Shared_Test } from "../../shared/lockup-linear/createWithDurations.t.sol";
import { LockupLinear_Integration_Fuzz_Test } from "./LockupLinear.t.sol";

contract CreateWithDurations_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    CreateWithDurations_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Fuzz_Test, CreateWithDurations_Integration_Shared_Test)
    {
        LockupLinear_Integration_Fuzz_Test.setUp();
        CreateWithDurations_Integration_Shared_Test.setUp();
    }

    function testFuzz_RevertWhen_CliffDurationCalculationOverflows(uint40 cliffDuration)
        external
        whenNotDelegateCalled
    {
        uint40 startTime = getBlockTimestamp();
        cliffDuration = boundUint40(cliffDuration, MAX_UINT40 - startTime + 1 seconds, MAX_UINT40);

        // Calculate the end time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
        }

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_StartTimeGreaterThanCliffTime.selector, startTime, cliffTime
            )
        );

        // Set the total duration to be the same as the cliff duration.
        uint40 totalDuration = cliffDuration;

        // Create the stream.
        createDefaultStreamWithDurations(LockupLinear.Durations({ cliff: cliffDuration, total: totalDuration }));
    }

    function testFuzz_RevertWhen_TotalDurationCalculationOverflows(LockupLinear.Durations memory durations)
        external
        whenNotDelegateCalled
        whenCliffDurationCalculationDoesNotOverflow
    {
        uint40 startTime = getBlockTimestamp();
        durations.cliff = boundUint40(durations.cliff, 0, MAX_UINT40 - startTime);
        durations.total = boundUint40(durations.total, MAX_UINT40 - startTime + 1 seconds, MAX_UINT40);

        // Calculate the cliff time and the end time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        uint40 endTime;
        unchecked {
            cliffTime = startTime + durations.cliff;
            endTime = startTime + durations.total;
        }

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeNotLessThanEndTime.selector, cliffTime, endTime
            )
        );

        // Create the stream.
        createDefaultStreamWithDurations(durations);
    }

    function testFuzz_CreateWithDurations(LockupLinear.Durations memory durations)
        external
        whenNotDelegateCalled
        whenCliffDurationCalculationDoesNotOverflow
        whenTotalDurationCalculationDoesNotOverflow
    {
        durations.total = boundUint40(durations.total, 0, MAX_UNIX_TIMESTAMP);
        vm.assume(durations.cliff < durations.total);

        // Make the Sender the stream's funder (recall that the Sender is the default caller).
        address funder = users.sender;

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = lockupLinear.protocolRevenues(dai);

        // Expect the assets to be transferred from the funder to {SablierV2LockupLinear}.
        expectCallToTransferFrom({
            from: funder,
            to: address(lockupLinear),
            amount: defaults.DEPOSIT_AMOUNT() + defaults.PROTOCOL_FEE_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, amount: defaults.BROKER_FEE_AMOUNT() });

        // Create the range struct by calculating the start time, cliff time and the end time.
        LockupLinear.Range memory range = LockupLinear.Range({
            start: getBlockTimestamp(),
            cliff: getBlockTimestamp() + durations.cliff,
            end: getBlockTimestamp() + durations.total
        });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockupLinear) });
        emit CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: dai,
            cancelable: true,
            range: range,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDurations(durations);

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = lockupLinear.getStream(streamId);
        LockupLinear.Stream memory expectedStream = defaults.lockupLinearStream();
        expectedStream.cliffTime = range.cliff;
        expectedStream.endTime = range.end;
        expectedStream.startTime = range.start;
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = lockupLinear.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = lockupLinear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = lockupLinear.protocolRevenues(dai);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + defaults.PROTOCOL_FEE_AMOUNT();
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        address actualNFTOwner = lockupLinear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
