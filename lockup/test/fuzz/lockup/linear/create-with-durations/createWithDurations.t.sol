// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupLinear } from "src/types/DataTypes.sol";

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

        // Calculate the end time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
        }

        // Expect a {StartTimeGreaterThanCliffTime} error.
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

    modifier whenCliffDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_TotalDurationCalculationOverflows(LockupLinear.Durations memory durations)
        external
        whenCliffDurationCalculationDoesNotOverflow
    {
        uint40 startTime = getBlockTimestamp();
        durations.cliff = boundUint40(durations.cliff, 0, UINT40_MAX - startTime);
        durations.total = boundUint40(durations.total, UINT40_MAX - startTime + 1, UINT40_MAX);

        // Calculate the cliff time and the end time. Needs to be "unchecked" to avoid an overflow.
        uint40 cliffTime;
        uint40 endTime;
        unchecked {
            cliffTime = startTime + durations.cliff;
            endTime = startTime + durations.total;
        }

        // Expect a {CliffTimeNotLessThanEndTime} error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeNotLessThanEndTime.selector, cliffTime, endTime
            )
        );

        // Create the stream.
        createDefaultStreamWithDurations(durations);
    }

    modifier whenTotalDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, record the
    /// protocol fee, mint the NFT, and emit a {CreateLockupLinearStream} event.
    function testFuzz_CreateWithDurations(LockupLinear.Durations memory durations) external {
        durations.total = boundUint40(durations.total, 0, MAX_UNIX_TIMESTAMP);
        vm.assume(durations.cliff < durations.total);

        // Make the sender the funder of the stream.
        address funder = users.sender;

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = linear.protocolRevenues(DEFAULT_ASSET);

        // Expect the ERC-20 assets to be transferred from the funder to {SablierV2LockupLinear}.
        expectTransferFromCall({
            from: funder,
            to: address(linear),
            amount: DEFAULT_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT
        });

        // Expect the broker fee to be paid to the broker, if the amount is not zero.
        expectTransferFromCall({ from: funder, to: users.broker, amount: DEFAULT_BROKER_FEE_AMOUNT });

        // Create the range struct by calculating the start time, cliff time and the end time.
        LockupLinear.Range memory range = LockupLinear.Range({
            start: getBlockTimestamp(),
            cliff: getBlockTimestamp() + durations.cliff,
            end: getBlockTimestamp() + durations.total
        });

        // Expect a {CreateLockupLinearStream} event to be emitted.
        vm.expectEmit({ emitter: address(linear) });
        emit CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: defaultParams.createWithDurations.sender,
            recipient: defaultParams.createWithDurations.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            asset: DEFAULT_ASSET,
            cancelable: defaultParams.createWithDurations.cancelable,
            range: range,
            broker: defaultParams.createWithDurations.broker.account
        });

        // Create the stream.
        createDefaultStreamWithDurations(durations);

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.cliffTime, range.cliff, "cliffTime");
        assertEq(actualStream.endTime, range.end, "endTime");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.startTime, range.start, "startTime");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = linear.protocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithDurations.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
