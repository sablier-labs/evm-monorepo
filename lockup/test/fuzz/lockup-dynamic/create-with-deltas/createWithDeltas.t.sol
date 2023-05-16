// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { CreateWithDeltas_Dynamic_Shared_Test } from
    "../../../shared/lockup-dynamic/create-with-deltas/createWithDeltas.t.sol";
import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

contract CreateWithDeltas_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test, CreateWithDeltas_Dynamic_Shared_Test {
    function setUp() public virtual override(Dynamic_Fuzz_Test, CreateWithDeltas_Dynamic_Shared_Test) {
        Dynamic_Fuzz_Test.setUp();
        CreateWithDeltas_Dynamic_Shared_Test.setUp();
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
        bool isSettled;
        LockupDynamic.Segment[] segmentsWithMilestones;
        uint128 totalAmount;
    }

    function testFuzz_CreateWithDeltas(LockupDynamic.SegmentWithDelta[] memory segments)
        external
        whenNotDelegateCalled
        whenLoopCalculationsDoNotOverflowBlockGasLimit
        whenDeltasNotZero
        whenMilestonesCalculationsDoNotOverflow
    {
        vm.assume(segments.length != 0);

        // Fuzz the deltas.
        Vars memory vars;
        fuzzSegmentDeltas(segments);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (vars.totalAmount, vars.createAmounts) = fuzzDynamicStreamAmounts(segments);

        // Make the sender the stream's funder (recall that the sender is the default caller).
        vars.funder = users.sender;

        // Load the initial protocol revenues.
        vars.initialProtocolRevenues = dynamic.protocolRevenues(dai);

        // Mint enough assets to the fuzzed funder.
        deal({ token: address(dai), to: vars.funder, give: vars.totalAmount });

        // Expect the assets to be transferred from the funder to {SablierV2LockupDynamic}.
        expectCallToTransferFrom({
            from: vars.funder,
            to: address(dynamic),
            amount: vars.createAmounts.deposit + vars.createAmounts.protocolFee
        });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectCallToTransferFrom({ from: vars.funder, to: users.broker, amount: vars.createAmounts.brokerFee });
        }

        // Create the range struct.
        vars.segmentsWithMilestones = getSegmentsWithMilestones(segments);
        LockupDynamic.Range memory range = LockupDynamic.Range({
            start: getBlockTimestamp(),
            end: vars.segmentsWithMilestones[vars.segmentsWithMilestones.length - 1].milestone
        });

        // Expect a {CreateLockupDynamicStream} event to be emitted.
        vm.expectEmit({ emitter: address(dynamic) });
        emit CreateLockupDynamicStream({
            streamId: streamId,
            funder: vars.funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: vars.createAmounts,
            asset: dai,
            cancelable: true,
            segments: vars.segmentsWithMilestones,
            range: range,
            broker: users.broker
        });

        // Create the stream.
        LockupDynamic.CreateWithDeltas memory params = defaults.createWithDeltas();
        params.segments = segments;
        params.totalAmount = vars.totalAmount;
        dynamic.createWithDeltas(params);

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts(vars.createAmounts.deposit, 0, 0));
        assertEq(actualStream.asset, dai, "asset");
        assertEq(actualStream.endTime, range.end, "endTime");
        assertEq(actualStream.isCancelable, true, "isCancelable");
        assertEq(actualStream.isDepleted, false, "isDepleted");
        assertEq(actualStream.isStream, true, "isStream");
        assertEq(actualStream.segments, vars.segmentsWithMilestones, "segments");
        assertEq(actualStream.sender, users.sender, "sender");
        assertEq(actualStream.startTime, range.start, "startTime");
        assertEq(actualStream.wasCanceled, false, "wasCanceled");

        // Check if the stream is settled. It is possible for a dynamic stream to settle at the time of creation
        // because some segment amounts can be zero.
        vars.isSettled = dynamic.refundableAmountOf(streamId) == 0;

        // Assert that the stream's status is correct.
        vars.actualStatus = dynamic.statusOf(streamId);
        vars.expectedStatus = vars.isSettled ? Lockup.Status.SETTLED : Lockup.Status.STREAMING;
        assertEq(vars.actualStatus, vars.expectedStatus);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = dynamic.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = dynamic.protocolRevenues(dai);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = dynamic.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = users.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
