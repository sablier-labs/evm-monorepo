// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/UD2x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { LockupPro } from "src/types/DataTypes.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract CreateWithDeltas_Pro_Unit_Test is Pro_Unit_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Pro_Unit_Test.setUp();

        // Load the stream id.
        streamId = pro.nextStreamId();
    }

    /// @dev it should revert.
    function test_RevertWhen_LoopCalculationOverflowsBlockGasLimit() external {
        LockupPro.SegmentWithDelta[] memory segments = new LockupPro.SegmentWithDelta[](250_000);
        vm.expectRevert(bytes(""));
        createDefaultStreamWithDeltas(segments);
    }

    modifier loopCalculationsDoNotOverflowBlockGasLimit() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_DeltasZero() external loopCalculationsDoNotOverflowBlockGasLimit {
        uint40 startTime = getBlockTimestamp();
        LockupPro.SegmentWithDelta[] memory segments = defaultParams.createWithDeltas.segments;
        segments[1].delta = 0;
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_SegmentMilestonesNotOrdered.selector,
                index,
                startTime + segments[0].delta,
                startTime + segments[0].delta
            )
        );
        createDefaultStreamWithDeltas(segments);
    }

    modifier deltasNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_MilestonesCalculationsOverflows_StartTimeNotLessThanFirstSegmentMilestone()
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();
            LockupPro.SegmentWithDelta[] memory segments = defaultParams.createWithDeltas.segments;
            segments[0].delta = UINT40_MAX;
            segments[1].delta = 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierV2LockupPro_StartTimeNotLessThanFirstSegmentMilestone.selector,
                    startTime,
                    startTime + segments[0].delta
                )
            );
            createDefaultStreamWithDeltas(segments);
        }
    }

    /// @dev it should revert.
    function test_RevertWhen_MilestonesCalculationsOverflows_SegmentMilestonesNotOrdered()
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();

            // Create new segments that overflow when the milestones are eventually calculated.
            LockupPro.SegmentWithDelta[] memory segments = new LockupPro.SegmentWithDelta[](3);
            segments[0] = LockupPro.SegmentWithDelta({ amount: 0, exponent: ud2x18(1e18), delta: startTime + 1 });
            segments[1] = LockupPro.SegmentWithDelta({
                amount: DEFAULT_SEGMENTS_WITH_DELTAS[0].amount,
                exponent: DEFAULT_SEGMENTS_WITH_DELTAS[0].exponent,
                delta: UINT40_MAX
            });
            segments[2] = LockupPro.SegmentWithDelta({
                amount: DEFAULT_SEGMENTS_WITH_DELTAS[1].amount,
                exponent: DEFAULT_SEGMENTS_WITH_DELTAS[1].exponent,
                delta: 1
            });

            // Expect a {SegmentMilestonesNotOrdered} error.
            uint256 index = 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierV2LockupPro_SegmentMilestonesNotOrdered.selector,
                    index,
                    startTime + segments[0].delta,
                    startTime + segments[0].delta + segments[1].delta
                )
            );

            // Create the stream.
            createDefaultStreamWithDeltas(segments);
        }
    }

    modifier milestonesCalculationsDoNotOverflow() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, mint the NFT,
    /// record the protocol fee, and emit a {CreateLockupProStream} event.
    function test_CreateWithDeltas()
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
        milestonesCalculationsDoNotOverflow
    {
        // Make the sender the funder of the stream.
        address funder = users.sender;

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        expectTransferFromCall({
            from: funder,
            to: address(pro),
            amount: DEFAULT_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT
        });

        // Expect the broker fee to be paid to the broker.
        expectTransferFromCall({ from: funder, to: users.broker, amount: DEFAULT_BROKER_FEE_AMOUNT });

        // Expect a {CreateLockupProStream} event to be emitted.
        expectEmit();
        emit CreateLockupProStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            asset: DEFAULT_ASSET,
            cancelable: true,
            segments: DEFAULT_SEGMENTS,
            range: DEFAULT_PRO_RANGE,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDeltas();

        // Assert that the stream has been created.
        LockupPro.Stream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream, defaultStream);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithDeltas.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
