// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Events } from "src/libraries/Events.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LockupPro } from "src/types/DataTypes.sol";

import { Pro_Fuzz_Test } from "../Pro.t.sol";

contract CreateWithDeltas_Pro_Fuzz_Test is Pro_Fuzz_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Pro_Fuzz_Test.setUp();

        // Load the stream id.
        streamId = pro.nextStreamId();
    }

    modifier loopCalculationsDoNotOverflowBlockGasLimit() {
        _;
    }

    modifier deltasNotZero() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_SegmentArraysCountsNotEqual(
        uint256 deltaCount
    ) external loopCalculationsDoNotOverflowBlockGasLimit deltasNotZero {
        deltaCount = bound(deltaCount, 1, 1_000);
        vm.assume(deltaCount != defaultParams.createWithDeltas.segments.length);

        uint40[] memory deltas = new uint40[](deltaCount);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_SegmentArrayCountsNotEqual.selector,
                defaultParams.createWithDeltas.segments.length,
                deltaCount
            )
        );
        createDefaultStreamWithDeltas(deltas);
    }

    modifier segmentArrayCountsEqual() {
        _;
    }

    modifier milestonesCalculationsDoNotOverflow() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, mint the NFT,
    /// record the protocol fee, and emit a {CreateLockupProStream} event.
    function testFuzz_CreateWithDeltas(
        uint40 delta0,
        uint40 delta1
    )
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
        segmentArrayCountsEqual
        milestonesCalculationsDoNotOverflow
    {
        delta0 = boundUint40(delta0, 0, 100);
        delta1 = boundUint40(delta1, 1, UINT40_MAX - getBlockTimestamp() - delta0);

        // Create the deltas.
        uint40[] memory deltas = Solarray.uint40s(delta0, delta1);

        // Adjust the segment milestones to match the fuzzed deltas.
        LockupPro.Segment[] memory segments = defaultParams.createWithDeltas.segments;
        segments[0].milestone = getBlockTimestamp() + delta0;
        segments[1].milestone = segments[0].milestone + delta1;

        // Make the sender the funder in this test.
        address funder = defaultParams.createWithDeltas.sender;

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(pro), DEFAULT_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT)
            )
        );

        // Expect the broker fee to be paid to the broker.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, defaultParams.createWithDeltas.broker.addr, DEFAULT_BROKER_FEE_AMOUNT)
            )
        );

        // Create the range struct.
        LockupPro.Range memory range = LockupPro.Range({ start: getBlockTimestamp(), end: segments[1].milestone });

        // Expect a {CreateLockupProStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupProStream({
            streamId: streamId,
            funder: funder,
            sender: defaultParams.createWithDeltas.sender,
            recipient: defaultParams.createWithDeltas.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            segments: segments,
            asset: DEFAULT_ASSET,
            cancelable: defaultParams.createWithDeltas.cancelable,
            range: range,
            broker: defaultParams.createWithDeltas.broker.addr
        });

        // Create the stream.
        pro.createWithDeltas(
            defaultParams.createWithDeltas.sender,
            defaultParams.createWithDeltas.recipient,
            defaultParams.createWithDeltas.totalAmount,
            segments,
            DEFAULT_ASSET,
            defaultParams.createWithDeltas.cancelable,
            deltas,
            defaultParams.createWithDeltas.broker
        );

        // Assert that the stream was created.
        LockupPro.Stream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.range, range);
        assertEq(actualStream.segments, segments);
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithDeltas.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
