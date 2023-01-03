// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length
pragma solidity >=0.8.13;
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD1x18, sd1x18 } from "@prb/math/SD1x18.sol";
import { Solarray } from "solarray/Solarray.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Events } from "src/libraries/Events.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ProStream, Segment } from "src/types/Structs.sol";

import { ProTest } from "../ProTest.t.sol";

contract CreateWithDeltas__ProTest is ProTest {
    /// @dev it should revert.
    function testCannotCreateWithDeltas__LoopCalculationOverflowsBlockGasLimit() external {
        uint40[] memory deltas = new uint40[](1_000_000);
        vm.expectRevert(bytes(""));
        createDefaultStreamWithDeltas(deltas);
    }

    modifier LoopCalculationsDoNotOverflowBlockGasLimit() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithDeltas__DeltasZero() external LoopCalculationsDoNotOverflowBlockGasLimit {
        uint40 startTime = getBlockTimestamp();
        uint40[] memory deltas = Solarray.uint40s(DEFAULT_SEGMENT_DELTAS[0], 0);
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                index,
                startTime + deltas[0],
                startTime + deltas[0]
            )
        );
        createDefaultStreamWithDeltas(deltas);
    }

    modifier DeltasNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithDeltas__SegmentArraysNotEqual(
        uint256 deltaCount
    ) external LoopCalculationsDoNotOverflowBlockGasLimit DeltasNotZero {
        deltaCount = bound(deltaCount, 1, 1_000);
        vm.assume(deltaCount != defaultArgs.createWithDeltas.segments.length);

        uint40[] memory deltas = new uint40[](deltaCount);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentArraysNotEqual.selector,
                defaultArgs.createWithDeltas.segments.length,
                deltaCount
            )
        );
        createDefaultStreamWithDeltas(deltas);
    }

    modifier SegmentArraysEqual() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreateWithDeltas__MilestonesCalculationsOverflows__StartTimeGreaterThanCalculatedFirstMilestone()
        external
        LoopCalculationsDoNotOverflowBlockGasLimit
        DeltasNotZero
        SegmentArraysEqual
    {
        uint40 startTime = getBlockTimestamp();
        uint40[] memory deltas = Solarray.uint40s(UINT40_MAX, 1);
        Segment[] memory segments = defaultArgs.createWithDeltas.segments;
        unchecked {
            segments[0].milestone = startTime + deltas[0];
            segments[1].milestone = deltas[0] + deltas[1];
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__StartTimeGreaterThanFirstMilestone.selector,
                startTime,
                segments[0].milestone
            )
        );
        createDefaultStreamWithDeltas(deltas);
    }

    /// @dev it should revert.
    function testCannotCreateWithDeltas__MilestonesCalculationsOverflows__SegmentMilestonesNotOrdered()
        external
        LoopCalculationsDoNotOverflowBlockGasLimit
        DeltasNotZero
        SegmentArraysEqual
    {
        uint40 startTime = getBlockTimestamp();

        // Create the deltas such that they overflow.
        uint40[] memory deltas = Solarray.uint40s(1, UINT40_MAX, 1);

        // Create new segments that overflow when the milestones are eventually calculated.
        Segment[] memory segments = new Segment[](3);
        unchecked {
            segments[0] = Segment({ amount: 0, exponent: sd1x18(1e18), milestone: startTime + deltas[0] });
            segments[1] = Segment({
                amount: DEFAULT_SEGMENTS[0].amount,
                exponent: DEFAULT_SEGMENTS[0].exponent,
                milestone: segments[0].milestone + deltas[1]
            });
            segments[2] = Segment({
                amount: DEFAULT_SEGMENTS[1].amount,
                exponent: DEFAULT_SEGMENTS[1].exponent,
                milestone: segments[1].milestone + deltas[2]
            });
        }

        // Expect an error.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                index,
                segments[0].milestone,
                segments[1].milestone
            )
        );

        // Create the stream.
        pro.createWithDeltas(
            defaultArgs.createWithDeltas.sender,
            defaultArgs.createWithDeltas.recipient,
            defaultArgs.createWithDeltas.grossDepositAmount,
            segments,
            defaultArgs.createWithDeltas.operator,
            defaultArgs.createWithDeltas.operatorFee,
            defaultArgs.createWithDeltas.token,
            defaultArgs.createWithDeltas.cancelable,
            deltas
        );
    }

    modifier MilestonesCalculationsDoNotOverflow() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    function testCreateWithDeltas(
        uint40 delta0,
        uint40 delta1
    )
        external
        LoopCalculationsDoNotOverflowBlockGasLimit
        DeltasNotZero
        SegmentArraysEqual
        MilestonesCalculationsDoNotOverflow
    {
        delta0 = boundUint40(delta0, 0, 100);
        delta1 = boundUint40(delta1, 1, UINT40_MAX - getBlockTimestamp() - delta0);

        // Create the deltas.
        uint40[] memory deltas = Solarray.uint40s(delta0, delta1);

        // Adjust the segment milestones to match the fuzzed deltas.
        Segment[] memory segments = defaultArgs.createWithDeltas.segments;
        segments[0].milestone = getBlockTimestamp() + delta0;
        segments[1].milestone = segments[0].milestone + delta1;

        // Make the sender the funder in this test.
        address funder = defaultArgs.createWithDeltas.sender;

        // Expect the tokens to be transferred from the funder to the SablierV2Pro contract.
        vm.expectCall(
            address(defaultArgs.createWithDeltas.token),
            abi.encodeCall(IERC20.transferFrom, (funder, address(pro), DEFAULT_NET_DEPOSIT_AMOUNT))
        );

        // Expect the operator fee to be paid to the operator.
        vm.expectCall(
            address(defaultArgs.createWithDeltas.token),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, defaultArgs.createWithDeltas.operator, DEFAULT_OPERATOR_FEE_AMOUNT)
            )
        );

        // Create the stream.
        uint256 streamId = pro.createWithDeltas(
            defaultArgs.createWithDeltas.sender,
            defaultArgs.createWithDeltas.recipient,
            defaultArgs.createWithDeltas.grossDepositAmount,
            segments,
            defaultArgs.createWithDeltas.operator,
            defaultArgs.createWithDeltas.operatorFee,
            defaultArgs.createWithDeltas.token,
            defaultArgs.createWithDeltas.cancelable,
            deltas
        );

        // Assert that the stream was created.
        ProStream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.isEntity, defaultStream.isEntity);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.segments, segments);
        assertEq(actualStream.startTime, defaultStream.startTime);
        assertEq(actualStream.token, defaultStream.token);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultArgs.createWithDeltas.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    /// @dev it should record the protocol fee.
    function testCreateWithDeltas__ProtocolFee()
        external
        LoopCalculationsDoNotOverflowBlockGasLimit
        DeltasNotZero
        SegmentArraysEqual
        MilestonesCalculationsDoNotOverflow
    {
        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = pro.getProtocolRevenues(defaultArgs.createWithDeltas.token);

        // Create the default stream.
        createDefaultStream();

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(defaultArgs.createWithDeltas.token);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    /// @dev it should create a CreateProStream event.
    function testCreateWithDeltas__Event()
        external
        LoopCalculationsDoNotOverflowBlockGasLimit
        DeltasNotZero
        SegmentArraysEqual
        MilestonesCalculationsDoNotOverflow
    {
        uint256 streamId = pro.nextStreamId();
        address funder = defaultArgs.createWithDeltas.sender;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateProStream({
            streamId: streamId,
            funder: funder,
            sender: defaultArgs.createWithDeltas.sender,
            recipient: defaultArgs.createWithDeltas.recipient,
            depositAmount: DEFAULT_NET_DEPOSIT_AMOUNT,
            segments: defaultArgs.createWithDeltas.segments,
            protocolFeeAmount: DEFAULT_PROTOCOL_FEE_AMOUNT,
            operator: defaultArgs.createWithDeltas.operator,
            operatorFeeAmount: DEFAULT_OPERATOR_FEE_AMOUNT,
            token: defaultArgs.createWithDeltas.token,
            cancelable: defaultArgs.createWithDeltas.cancelable,
            startTime: DEFAULT_START_TIME
        });
        createDefaultStream();
    }
}
