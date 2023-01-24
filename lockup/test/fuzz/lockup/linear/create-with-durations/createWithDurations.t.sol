// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";
import { Durations, LockupAmounts, LockupLinearStream, Range } from "src/types/Structs.sol";

import { Linear_Fuzz_Test } from "../Linear.t.sol";

contract CreateWithDurations_Linear_Fuzz_Test is Linear_Fuzz_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Linear_Fuzz_Test.setUp();

        // Load the stream id.
        streamId = linear.nextStreamId();
    }

    /// @dev it should revert due to the start time being greater than the cliff time.
    function testFuzz_RevertWhen_CliffDurationCalculationOverflows(uint40 cliffDuration) external {
        uint40 startTime = getBlockTimestamp();
        cliffDuration = boundUint40(cliffDuration, UINT40_MAX - startTime + 1, UINT40_MAX);

        // Calculate the stop time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
        }

        // Expect an error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_StartTimeGreaterThanCliffTime.selector,
                startTime,
                cliffTime
            )
        );

        // Set the total duration to be the same as the cliff duration.
        uint40 totalDuration = cliffDuration;

        // Create the stream.
        createDefaultStreamWithDurations(Durations({ cliff: cliffDuration, total: totalDuration }));
    }

    modifier cliffDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_TotalDurationCalculationOverflows(
        Durations memory durations
    ) external cliffDurationCalculationDoesNotOverflow {
        uint40 startTime = getBlockTimestamp();
        durations.cliff = boundUint40(durations.cliff, 0, UINT40_MAX - startTime);
        durations.total = boundUint40(durations.total, UINT40_MAX - startTime + 1, UINT40_MAX);

        // Calculate the cliff time and the stop time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        uint40 stopTime;
        unchecked {
            cliffTime = startTime + durations.cliff;
            stopTime = startTime + durations.total;
        }

        // Expect an error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeGreaterThanStopTime.selector,
                cliffTime,
                stopTime
            )
        );

        // Create the stream.
        createDefaultStreamWithDurations(durations);
    }

    modifier totalDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, record the
    /// protocol fee, mint the NFT, and emit a {CreateLockupLinearStream} event.
    function testFuzz_CreateWithDurations(Durations memory durations) external {
        durations.total = boundUint40(durations.total, 0, UINT40_MAX - getBlockTimestamp());
        vm.assume(durations.cliff <= durations.total);

        // Make the sender the funder in this test.
        address funder = defaultParams.createWithDurations.sender;

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = linear.getProtocolRevenues(DEFAULT_ASSET);

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupLinear} contract.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(linear), DEFAULT_NET_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT)
            )
        );

        // Expect the broker fee to be paid to the broker, if the amount is not zero.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, defaultParams.createWithDurations.broker.addr, DEFAULT_BROKER_FEE_AMOUNT)
            )
        );

        // Calculate the start time, cliff time and the stop time.
        Range memory range = Range({
            start: getBlockTimestamp(),
            cliff: getBlockTimestamp() + durations.cliff,
            stop: getBlockTimestamp() + durations.total
        });

        // Expect a {CreateLockupLinearStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: defaultParams.createWithDurations.sender,
            recipient: defaultParams.createWithDurations.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            asset: DEFAULT_ASSET,
            cancelable: defaultParams.createWithDurations.cancelable,
            range: range,
            broker: defaultParams.createWithDurations.broker.addr
        });

        // Create the stream.
        createDefaultStreamWithDurations(durations);

        // Assert that the stream was created.
        LockupLinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.range, range);
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT was minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithDurations.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
