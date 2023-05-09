// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ud2x18 } from "@prb/math/UD2x18.sol";

import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { CreateWithDeltas_Dynamic_Shared_Test } from
    "../../../shared/lockup-dynamic/create-with-deltas/createWithDeltas.t.sol";
import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract CreateWithDeltas_Dynamic_Unit_Test is Dynamic_Unit_Test, CreateWithDeltas_Dynamic_Shared_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, CreateWithDeltas_Dynamic_Shared_Test) {
        Dynamic_Unit_Test.setUp();
        CreateWithDeltas_Dynamic_Shared_Test.setUp();
        streamId = dynamic.nextStreamId();
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2LockupDynamic.createWithDeltas, defaults.createWithDeltas());
        (bool success, bytes memory returnData) = address(dynamic).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    /// @dev it should revert.
    function test_RevertWhen_LoopCalculationOverflowsBlockGasLimit() external whenNoDelegateCall {
        LockupDynamic.SegmentWithDelta[] memory segments = new LockupDynamic.SegmentWithDelta[](250_000);
        vm.expectRevert(bytes(""));
        createDefaultStreamWithDeltas(segments);
    }

    function test_RevertWhen_DeltasZero() external whenNoDelegateCall whenLoopCalculationsDoNotOverflowBlockGasLimit {
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
        whenNoDelegateCall
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
        whenNoDelegateCall
        whenLoopCalculationsDoNotOverflowBlockGasLimit
        whenDeltasNotZero
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();

            // Create new segments that overflow when the milestones are eventually calculated.
            LockupDynamic.SegmentWithDelta[] memory segments = new LockupDynamic.SegmentWithDelta[](2);
            segments[0] = LockupDynamic.SegmentWithDelta({ amount: 0, exponent: ud2x18(1e18), delta: startTime + 1 });
            segments[1] = defaults.segmentsWithDeltas()[0];
            segments[1].delta = MAX_UINT40;

            // Expect a {SegmentMilestonesNotOrdered} error.
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
        whenNoDelegateCall
        whenLoopCalculationsDoNotOverflowBlockGasLimit
        whenDeltasNotZero
        whenMilestonesCalculationsDoNotOverflow
    {
        // Make the sender the stream's funder
        address funder = users.sender;

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = dynamic.protocolRevenues(dai);

        // Expect the assets to be transferred from the funder to {SablierV2LockupDynamic}.
        expectCallToTransferFrom({
            from: funder,
            to: address(dynamic),
            amount: defaults.DEPOSIT_AMOUNT() + defaults.PROTOCOL_FEE_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, amount: defaults.BROKER_FEE_AMOUNT() });

        // Expect a {CreateLockupDynamicStream} event to be emitted.
        vm.expectEmit({ emitter: address(dynamic) });
        emit CreateLockupDynamicStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: dai,
            cancelable: true,
            segments: defaults.segments(),
            range: defaults.dynamicRange(),
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDeltas();

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaults.dynamicStream();
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = dynamic.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = dynamic.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = dynamic.protocolRevenues(dai);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + defaults.PROTOCOL_FEE_AMOUNT();
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        address actualNFTOwner = dynamic.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
