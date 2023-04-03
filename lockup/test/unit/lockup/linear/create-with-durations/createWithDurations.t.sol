// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract CreateWithDurations_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Linear_Unit_Test.setUp();

        // Load the stream id.
        streamId = linear.nextStreamId();
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2LockupLinear.createWithDurations, defaultParams.createWithDurations);
        (bool success, bytes memory returnData) = address(linear).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    /// @dev it should revert due to the start time being greater than the cliff time.
    function test_RevertWhen_CliffDurationCalculationOverflows() external whenNoDelegateCall {
        uint40 startTime = getBlockTimestamp();
        uint40 cliffDuration = UINT40_MAX - startTime + 1;

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
    function test_RevertWhen_TotalDurationCalculationOverflows()
        external
        whenNoDelegateCall
        whenCliffDurationCalculationDoesNotOverflow
    {
        uint40 startTime = getBlockTimestamp();
        LockupLinear.Durations memory durations =
            LockupLinear.Durations({ cliff: 0, total: UINT40_MAX - startTime + 1 });

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
    function test_CreateWithDurations()
        external
        whenNoDelegateCall
        whenCliffDurationCalculationDoesNotOverflow
        whenTotalDurationCalculationDoesNotOverflow
    {
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

        // Expect the broker fee to be paid to the broker.
        expectTransferFromCall({ from: funder, to: users.broker, amount: DEFAULT_BROKER_FEE_AMOUNT });

        // Expect a {CreateLockupLinearStream} event to be emitted.
        vm.expectEmit({ emitter: address(linear) });
        emit CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            asset: DEFAULT_ASSET,
            cancelable: true,
            range: DEFAULT_LINEAR_RANGE,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDurations({ durations: defaultParams.createWithDurations.durations });

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream, defaultStream);

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
