// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { CreateWithDeltas_Integration_Shared_Test } from "../../../shared/lockup-dynamic/createWithDeltas.t.sol";
import { LockupDynamic_Integration_Concrete_Test } from "../LockupDynamic.t.sol";

contract CreateWithDeltas_LockupDynamic_Integration_Concrete_Test is
    LockupDynamic_Integration_Concrete_Test,
    CreateWithDeltas_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(LockupDynamic_Integration_Concrete_Test, CreateWithDeltas_Integration_Shared_Test)
    {
        LockupDynamic_Integration_Concrete_Test.setUp();
        CreateWithDeltas_Integration_Shared_Test.setUp();
        streamId = lockupDynamic.nextStreamId();
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(ISablierV2LockupDynamic.createWithDeltas, defaults.createWithDeltas());
        (bool success, bytes memory returnData) = address(lockupDynamic).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    /// @dev it should revert.
    function test_RevertWhen_LoopCalculationOverflowsBlockGasLimit() external whenNotDelegateCalled {
        LockupDynamic.SegmentWithDelta[] memory segments = new LockupDynamic.SegmentWithDelta[](250_000);
        vm.expectRevert(bytes(""));
        createDefaultStreamWithDeltas(segments);
    }

    function test_RevertWhen_DeltasZero()
        external
        whenNotDelegateCalled
        whenLoopCalculationsDoNotOverflowBlockGasLimit
    {
        uint40 startTime = getBlockTimestamp();
        LockupDynamic.SegmentWithDelta[] memory segments = defaults.createWithDeltas().segments;
        segments[1].delta = 0;
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupDynamic_SegmentMilestonesNotOrdered.selector,
                index,
                startTime + segments[0].delta,
                startTime + segments[0].delta
            )
        );
        createDefaultStreamWithDeltas(segments);
    }

    function test_RevertWhen_MilestonesCalculationsOverflows_StartTimeNotLessThanFirstSegmentMilestone()
        external
        whenNotDelegateCalled
        whenLoopCalculationsDoNotOverflowBlockGasLimit
        whenDeltasNotZero
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();
            LockupDynamic.SegmentWithDelta[] memory segments = defaults.createWithDeltas().segments;
            segments[0].delta = MAX_UINT40;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierV2LockupDynamic_StartTimeNotLessThanFirstSegmentMilestone.selector,
                    startTime,
                    startTime + segments[0].delta
                )
            );
            createDefaultStreamWithDeltas(segments);
        }
    }

    function test_RevertWhen_MilestonesCalculationsOverflows_SegmentMilestonesNotOrdered()
        external
        whenNotDelegateCalled
        whenLoopCalculationsDoNotOverflowBlockGasLimit
        whenDeltasNotZero
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();

            // Create new segments that overflow when the milestones are eventually calculated.
            LockupDynamic.SegmentWithDelta[] memory segments = new LockupDynamic.SegmentWithDelta[](2);
            segments[0] =
                LockupDynamic.SegmentWithDelta({ amount: 0, exponent: ud2x18(1e18), delta: startTime + 1 seconds });
            segments[1] = defaults.segmentsWithDeltas()[0];
            segments[1].delta = MAX_UINT40;

            // Expect the relevant error to be thrown.
            uint256 index = 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierV2LockupDynamic_SegmentMilestonesNotOrdered.selector,
                    index,
                    startTime + segments[0].delta,
                    startTime + segments[0].delta + segments[1].delta
                )
            );

            // Create the stream.
            createDefaultStreamWithDeltas(segments);
        }
    }

    function test_CreateWithDeltas()
        external
        whenNotDelegateCalled
        whenLoopCalculationsDoNotOverflowBlockGasLimit
        whenDeltasNotZero
        whenMilestonesCalculationsDoNotOverflow
    {
        // Make the Sender the stream's funder
        address funder = users.sender;

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = lockupDynamic.protocolRevenues(dai);

        // Declare the range.
        uint40 currentTime = getBlockTimestamp();
        LockupDynamic.Range memory range =
            LockupDynamic.Range({ start: currentTime, end: currentTime + defaults.TOTAL_DURATION() });

        // Adjust the segments.
        LockupDynamic.SegmentWithDelta[] memory segmentsWithDeltas = defaults.segmentsWithDeltas();
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].milestone = range.start + segmentsWithDeltas[0].delta;
        segments[1].milestone = segments[0].milestone + segmentsWithDeltas[1].delta;

        // Expect the assets to be transferred from the funder to {SablierV2LockupDynamic}.
        expectCallToTransferFrom({
            from: funder,
            to: address(lockupDynamic),
            amount: defaults.DEPOSIT_AMOUNT() + defaults.PROTOCOL_FEE_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, amount: defaults.BROKER_FEE_AMOUNT() });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockupDynamic) });
        emit CreateLockupDynamicStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: dai,
            cancelable: true,
            segments: segments,
            range: range,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDeltas();

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = lockupDynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaults.lockupDynamicStream();
        expectedStream.endTime = range.end;
        expectedStream.segments = segments;
        expectedStream.startTime = range.start;
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = lockupDynamic.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = lockupDynamic.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = lockupDynamic.protocolRevenues(dai);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + defaults.PROTOCOL_FEE_AMOUNT();
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        address actualNFTOwner = lockupDynamic.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
