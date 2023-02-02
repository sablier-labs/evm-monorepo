// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Events } from "src/libraries/Events.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupPro } from "src/types/DataTypes.sol";

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
        vm.assume(deltaCount != DEFAULT_SEGMENTS.length);

        uint40[] memory deltas = new uint40[](deltaCount);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_SegmentArrayCountsNotEqual.selector,
                DEFAULT_SEGMENTS.length,
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

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        Lockup.CreateAmounts amounts;
        uint40[] deltas;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        address funder;
        uint128 initialProtocolRevenues;
        uint128 totalAmount;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, mint the NFT,
    /// record the protocol fee, and emit a {CreateLockupProStream} event.
    function testFuzz_CreateWithDeltas(
        LockupPro.Segment[] memory segments
    )
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
        segmentArrayCountsEqual
        milestonesCalculationsDoNotOverflow
    {
        vm.assume(segments.length != 0);

        // Fuzz the deltas and update the segment milestones.
        Vars memory vars;
        vars.deltas = fuzzSegmentDeltas(segments);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (vars.totalAmount, vars.amounts) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: UINT128_MAX,
            segments: segments,
            protocolFee: DEFAULT_PROTOCOL_FEE,
            brokerFee: DEFAULT_BROKER_FEE
        });

        // Make the sender the funder in this test.
        vars.funder = users.sender;

        // Load the initial protocol revenues.
        vars.initialProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);

        // Mint enough ERC-20 assets to the fuzzed funder.
        deal({ token: address(DEFAULT_ASSET), to: vars.funder, give: vars.totalAmount });

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (vars.funder, address(pro), vars.amounts.deposit + vars.amounts.protocolFee)
            )
        );

        // Expect the broker fee to be paid to the broker.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (vars.funder, defaultParams.createWithDeltas.broker.addr, vars.amounts.brokerFee)
            )
        );

        // Create the range struct.
        LockupPro.Range memory range = LockupPro.Range({
            start: getBlockTimestamp(),
            end: segments[segments.length - 1].milestone
        });

        // Expect a {CreateLockupProStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupProStream({
            streamId: streamId,
            funder: vars.funder,
            sender: defaultParams.createWithDeltas.sender,
            recipient: defaultParams.createWithDeltas.recipient,
            amounts: vars.amounts,
            segments: segments,
            asset: defaultParams.createWithDeltas.asset,
            cancelable: defaultParams.createWithDeltas.cancelable,
            range: range,
            broker: defaultParams.createWithDeltas.broker.addr
        });

        // Create the stream.
        pro.createWithDeltas(
            defaultParams.createWithDeltas.sender,
            defaultParams.createWithDeltas.recipient,
            vars.totalAmount,
            segments,
            DEFAULT_ASSET,
            defaultParams.createWithDeltas.cancelable,
            vars.deltas,
            defaultParams.createWithDeltas.broker
        );

        // Assert that the stream has been created.
        LockupPro.Stream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts({ deposit: vars.amounts.deposit, withdrawn: 0 }));
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.range, range);
        assertEq(actualStream.segments, segments);
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = pro.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.amounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = defaultParams.createWithDeltas.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
