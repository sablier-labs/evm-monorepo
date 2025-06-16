// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupDynamic } from "src/types/LockupDynamic.sol";
import { LockupLinear } from "src/types/LockupLinear.sol";
import { LockupTranched } from "src/types/LockupTranched.sol";

import { Calculations } from "tests/utils/Calculations.sol";
import { LockupStore } from "../stores/LockupStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract is a complement of {LockupHandler}.
contract LockupCreateHandler is BaseHandler, Calculations {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupStore public lockupStore;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 token_, LockupStore lockupStore_, ISablierLockup lockup_) BaseHandler(token_, lockup_) {
        lockupStore = lockupStore_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDurationsLD(
        uint256 timeJumpSeed,
        Lockup.CreateWithDurations memory params,
        LockupDynamic.SegmentWithDuration[] memory segments
    )
        public
        instrument("createWithDurationsLD")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty segment arrays.
        vm.assume(segments.length != 0);

        // Fuzz the durations.
        fuzzSegmentDurations(segments);

        // Fuzz the segment amounts and calculate the total amount.
        params.depositAmount = fuzzDynamicStreamAmounts({ upperBound: 1_000_000_000e18, segments: segments });

        // Mint enough tokens to the Sender.
        deal({ token: address(token), to: params.sender, give: token.balanceOf(params.sender) + params.depositAmount });

        // Approve {SablierLockup} to spend the tokens.
        token.approve({ spender: address(lockup), value: params.depositAmount });

        // Create the stream.
        params.token = token;
        params.shape = "Dynamic Stream";
        uint256 streamId = lockup.createWithDurationsLD(params, segments);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithDurationsLL(
        uint256 timeJumpSeed,
        Lockup.CreateWithDurations memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        LockupLinear.Durations memory durations
    )
        public
        instrument("createWithDurationsLL")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        (params, unlockAmounts, durations) = _boundCreateWithDurationsLLParams(params, unlockAmounts, durations);

        // Mint enough tokens to the Sender.
        deal({ token: address(token), to: params.sender, give: token.balanceOf(params.sender) + params.depositAmount });

        // Approve {SablierLockup} to spend the tokens.
        token.approve({ spender: address(lockup), value: params.depositAmount });

        // Create the stream.
        params.token = token;
        params.shape = "Linear Stream";
        uint256 streamId = lockup.createWithDurationsLL(params, unlockAmounts, durations);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithDurationsLT(
        uint256 timeJumpSeed,
        Lockup.CreateWithDurations memory params,
        LockupTranched.TrancheWithDuration[] memory tranches
    )
        public
        instrument("createWithDurationsLT")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty tranche arrays.
        vm.assume(tranches.length != 0);

        // Fuzz the durations.
        fuzzTrancheDurations(tranches);

        // Fuzz the tranche amounts and calculate the total amount.
        params.depositAmount = fuzzTranchedStreamAmounts({ upperBound: 1_000_000_000e18, tranches: tranches });

        // Mint enough tokens to the Sender.
        deal({ token: address(token), to: params.sender, give: token.balanceOf(params.sender) + params.depositAmount });

        // Approve {SablierLockup} to spend the tokens.
        token.approve({ spender: address(lockup), value: params.depositAmount });

        // Create the stream.
        params.token = token;
        params.shape = "Tranched Stream";
        uint256 streamId = lockup.createWithDurationsLT(params, tranches);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithTimestampsLD(
        uint256 timeJumpSeed,
        Lockup.CreateWithTimestamps memory params,
        LockupDynamic.Segment[] memory segments
    )
        public
        instrument("createWithTimestampsLD")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty segment arrays.
        vm.assume(segments.length != 0);

        params.timestamps.start = boundUint40(params.timestamps.start, 1, getBlockTimestamp());

        // Fuzz the segment timestamps.
        fuzzSegmentTimestamps(segments, params.timestamps.start);

        // Fuzz the segment amounts and calculate the total amount.
        params.depositAmount = fuzzDynamicStreamAmounts({ upperBound: 1_000_000_000e18, segments: segments });

        // Mint enough tokens to the Sender.
        deal({ token: address(token), to: params.sender, give: token.balanceOf(params.sender) + params.depositAmount });

        // Approve {SablierLockup} to spend the tokens.
        token.approve({ spender: address(lockup), value: params.depositAmount });

        // Create the stream.
        params.token = token;
        params.shape = "Dynamic Stream";
        params.timestamps.end = segments[segments.length - 1].timestamp;
        uint256 streamId = lockup.createWithTimestampsLD(params, segments);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithTimestampsLL(
        uint256 timeJumpSeed,
        Lockup.CreateWithTimestamps memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        uint40 cliffTime
    )
        public
        instrument("createWithTimestampsLL")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        (params, unlockAmounts, cliffTime) = _boundCreateWithTimestampsLLParams(params, unlockAmounts, cliffTime);

        // Mint enough tokens to the Sender.
        deal({ token: address(token), to: params.sender, give: token.balanceOf(params.sender) + params.depositAmount });

        // Approve {SablierLockup} to spend the tokens.
        token.approve({ spender: address(lockup), value: params.depositAmount });

        // Create the stream.
        params.token = token;
        params.shape = "Linear Stream";
        uint256 streamId = lockup.createWithTimestampsLL(params, unlockAmounts, cliffTime);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithTimestampsLT(
        uint256 timeJumpSeed,
        Lockup.CreateWithTimestamps memory params,
        LockupTranched.Tranche[] memory tranches
    )
        public
        instrument("createWithTimestampsLT")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty tranche arrays.
        vm.assume(tranches.length != 0);

        params.timestamps.start = boundUint40(params.timestamps.start, 1, getBlockTimestamp());

        // Fuzz the tranche timestamps.
        fuzzTrancheTimestamps(tranches, params.timestamps.start);

        // Fuzz the tranche amounts and calculate the total amount.
        params.depositAmount = fuzzTranchedStreamAmounts({ upperBound: 1_000_000_000e18, tranches: tranches });

        // Mint enough tokens to the Sender.
        deal({ token: address(token), to: params.sender, give: token.balanceOf(params.sender) + params.depositAmount });

        // Approve {SablierLockup} to spend the tokens.
        token.approve({ spender: address(lockup), value: params.depositAmount });

        // Create the stream.
        params.token = token;
        params.shape = "Tranched Stream";
        params.timestamps.end = tranches[tranches.length - 1].timestamp;
        uint256 streamId = lockup.createWithTimestampsLT(params, tranches);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to bound the params of the `createWithDurationsLL` function so that all the requirements are
    /// respected.
    /// @dev Function needed to prevent "Stack too deep error".
    function _boundCreateWithDurationsLLParams(
        Lockup.CreateWithDurations memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        LockupLinear.Durations memory durations
    )
        private
        pure
        returns (Lockup.CreateWithDurations memory, LockupLinear.UnlockAmounts memory, LockupLinear.Durations memory)
    {
        // Bound the stream parameters.

        durations.cliff = boundUint40(durations.cliff, 1 seconds, 2500 seconds);
        durations.total = boundUint40(durations.total, durations.cliff + 1 seconds, MAX_UNIX_TIMESTAMP);
        params.depositAmount = boundUint128(params.depositAmount, 1, 1_000_000_000e18);
        unlockAmounts.start = boundUint128(unlockAmounts.start, 0, params.depositAmount);
        unlockAmounts.cliff = params.depositAmount == unlockAmounts.start
            ? 0
            : boundUint128(unlockAmounts.cliff, 0, params.depositAmount - unlockAmounts.start);

        return (params, unlockAmounts, durations);
    }

    /// @notice Function to bound the params of the `createWithTimestampsLL` function so that all the requirements are
    /// respected.
    /// @dev Function needed to prevent "Stack too deep error".
    function _boundCreateWithTimestampsLLParams(
        Lockup.CreateWithTimestamps memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        uint40 cliffTime
    )
        private
        view
        returns (Lockup.CreateWithTimestamps memory, LockupLinear.UnlockAmounts memory, uint40)
    {
        uint40 blockTimestamp = getBlockTimestamp();

        params.timestamps.start = boundUint40(params.timestamps.start, 1 seconds, blockTimestamp);
        params.depositAmount = boundUint128(params.depositAmount, 1, 1_000_000_000e18);
        unlockAmounts.start = boundUint128(unlockAmounts.start, 0, params.depositAmount);
        unlockAmounts.cliff = 0;

        // The cliff time must be either zero or greater than the start time.
        if (cliffTime > 0) {
            cliffTime = boundUint40(cliffTime, params.timestamps.start + 1 seconds, params.timestamps.start + 52 weeks);

            unlockAmounts.cliff = params.depositAmount == unlockAmounts.start
                ? 0
                : boundUint128(unlockAmounts.cliff, 0, params.depositAmount - unlockAmounts.start);
        }

        // Bound the end time so that it is always greater than the start time, and the cliff time.
        uint40 endTimeLowerBound = maxOfTwo(params.timestamps.start, cliffTime);
        params.timestamps.end = boundUint40(params.timestamps.end, endTimeLowerBound + 1 seconds, MAX_UNIX_TIMESTAMP);

        return (params, unlockAmounts, cliffTime);
    }
}
