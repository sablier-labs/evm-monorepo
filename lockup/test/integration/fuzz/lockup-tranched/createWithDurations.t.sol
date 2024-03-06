// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup, LockupTranched } from "src/types/DataTypes.sol";

import { CreateWithDurations_Integration_Shared_Test } from "../../shared/lockup-tranched/createWithDurations.t.sol";
import { LockupTranched_Integration_Fuzz_Test } from "./LockupTranched.t.sol";

contract CreateWithDurations_LockupTranched_Integration_Fuzz_Test is
    LockupTranched_Integration_Fuzz_Test,
    CreateWithDurations_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(LockupTranched_Integration_Fuzz_Test, CreateWithDurations_Integration_Shared_Test)
    {
        LockupTranched_Integration_Fuzz_Test.setUp();
        CreateWithDurations_Integration_Shared_Test.setUp();
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        Lockup.Status actualStatus;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        Lockup.Status expectedStatus;
        address funder;
        uint128 initialProtocolRevenues;
        bool isCancelable;
        bool isSettled;
        LockupTranched.Tranche[] tranchesWithTimestamps;
        uint128 totalAmount;
    }

    function testFuzz_CreateWithDurations(LockupTranched.TrancheWithDuration[] memory tranches)
        external
        whenNotDelegateCalled
        whenLoopCalculationsDoNotOverflowBlockGasLimit
        whenDurationsNotZero
        whenTimestampsCalculationsDoNotOverflow
    {
        vm.assume(tranches.length != 0);

        // Fuzz the durations.
        Vars memory vars;
        fuzzTrancheDurations(tranches);

        // Fuzz the tranche amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (vars.totalAmount, vars.createAmounts) = fuzzTranchedStreamAmounts(tranches);

        // Make the Sender the stream's funder (recall that the Sender is the default caller).
        vars.funder = users.sender;

        // Load the initial protocol revenues.
        vars.initialProtocolRevenues = lockupTranched.protocolRevenues(dai);

        // Mint enough assets to the fuzzed funder.
        deal({ token: address(dai), to: vars.funder, give: vars.totalAmount });

        // Expect the assets to be transferred from the funder to {SablierV2LockupTranched}.
        expectCallToTransferFrom({
            from: vars.funder,
            to: address(lockupTranched),
            value: vars.createAmounts.deposit + vars.createAmounts.protocolFee
        });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectCallToTransferFrom({ from: vars.funder, to: users.broker, value: vars.createAmounts.brokerFee });
        }

        // Create the range struct.
        vars.tranchesWithTimestamps = getTranchesWithTimestamps(tranches);
        LockupTranched.Range memory range = LockupTranched.Range({
            start: getBlockTimestamp(),
            end: vars.tranchesWithTimestamps[vars.tranchesWithTimestamps.length - 1].timestamp
        });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockupTranched) });
        emit CreateLockupTranchedStream({
            streamId: streamId,
            funder: vars.funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: vars.createAmounts,
            asset: dai,
            cancelable: true,
            transferable: true,
            tranches: vars.tranchesWithTimestamps,
            range: range,
            broker: users.broker
        });

        // Create the stream.
        LockupTranched.CreateWithDurations memory params = defaults.createWithDurationsLT();
        params.tranches = tranches;
        params.totalAmount = vars.totalAmount;
        params.transferable = true;
        lockupTranched.createWithDurations(params);

        // Check if the stream is settled. It is possible for a Lockup Tranched stream to settle at the time of creation
        // because some tranche amounts can be zero.
        vars.isSettled = lockupTranched.refundableAmountOf(streamId) == 0;
        vars.isCancelable = vars.isSettled ? false : true;

        // Assert that the stream has been created.
        LockupTranched.StreamLT memory actualStream = lockupTranched.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts(vars.createAmounts.deposit, 0, 0));
        assertEq(actualStream.asset, dai, "asset");
        assertEq(actualStream.endTime, range.end, "endTime");
        assertEq(actualStream.isCancelable, vars.isCancelable, "isCancelable");
        assertEq(actualStream.isTransferable, true, "isTransferable");
        assertEq(actualStream.isDepleted, false, "isDepleted");
        assertEq(actualStream.isStream, true, "isStream");
        assertEq(actualStream.tranches, vars.tranchesWithTimestamps, "tranches");
        assertEq(actualStream.sender, users.sender, "sender");
        assertEq(actualStream.startTime, range.start, "startTime");
        assertEq(actualStream.wasCanceled, false, "wasCanceled");

        // Assert that the stream's status is correct.
        vars.actualStatus = lockupTranched.statusOf(streamId);
        vars.expectedStatus = vars.isSettled ? Lockup.Status.SETTLED : Lockup.Status.STREAMING;
        assertEq(vars.actualStatus, vars.expectedStatus);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = lockupTranched.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = lockupTranched.protocolRevenues(dai);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = lockupTranched.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = users.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
