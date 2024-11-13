// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "src/core/types/DataTypes.sol";

import { LockupStore } from "../stores/LockupStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract is a complement of {LockupHandler}.
contract LockupCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupStore public lockupStore;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, LockupStore lockupStore_, ISablierLockup lockup_) BaseHandler(asset_, lockup_) {
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
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty segment arrays.
        vm.assume(segments.length != 0);

        // Bound the broker fee.
        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);

        // Fuzz the durations.
        fuzzSegmentDurations(segments);

        // Fuzz the segment amounts and calculate the total amount.
        (params.totalAmount,) =
            fuzzDynamicStreamAmounts({ upperBound: 1_000_000_000e18, segments: segments, brokerFee: params.broker.fee });

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierLockup} to spend the assets.
        asset.approve({ spender: address(lockup), value: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = lockup.createWithDurationsLD(params, segments);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithDurationsLL(
        uint256 timeJumpSeed,
        Lockup.CreateWithDurations memory params,
        LockupLinear.Durations memory durations
    )
        public
        instrument("createWithDurationsLL")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // Bound the stream parameters.
        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);
        durations.cliff = boundUint40(durations.cliff, 1 seconds, 2500 seconds);
        durations.total = boundUint40(durations.total, durations.cliff + 1 seconds, MAX_UNIX_TIMESTAMP);
        params.totalAmount = boundUint128(params.totalAmount, 1, 1_000_000_000e18);

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierLockup} to spend the assets.
        asset.approve({ spender: address(lockup), value: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = lockup.createWithDurationsLL(params, durations);

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
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty tranche arrays.
        vm.assume(tranches.length != 0);

        // Bound the broker fee.
        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);

        // Fuzz the durations.
        fuzzTrancheDurations(tranches);

        // Fuzz the tranche amounts and calculate the total amount.
        (params.totalAmount,) = fuzzTranchedStreamAmounts({
            upperBound: 1_000_000_000e18,
            tranches: tranches,
            brokerFee: params.broker.fee
        });

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierLockup} to spend the assets.
        asset.approve({ spender: address(lockup), value: params.totalAmount });

        // Create the stream.
        params.asset = asset;
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
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty segment arrays.
        vm.assume(segments.length != 0);

        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);
        params.timestamps.start = boundUint40(params.timestamps.start, 1, getBlockTimestamp());

        // Fuzz the segment timestamps.
        fuzzSegmentTimestamps(segments, params.timestamps.start);

        // Fuzz the segment amounts and calculate the total amount.
        (params.totalAmount,) =
            fuzzDynamicStreamAmounts({ upperBound: 1_000_000_000e18, segments: segments, brokerFee: params.broker.fee });

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierLockup} to spend the assets.
        asset.approve({ spender: address(lockup), value: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        params.timestamps.end = segments[segments.length - 1].timestamp;
        uint256 streamId = lockup.createWithTimestampsLD(params, segments);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithTimestampsLL(
        uint256 timeJumpSeed,
        Lockup.CreateWithTimestamps memory params,
        uint40 cliffTime
    )
        public
        instrument("createWithTimestampsLL")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);
        params.timestamps.start = boundUint40(params.timestamps.start, 1 seconds, getBlockTimestamp());
        params.totalAmount = boundUint128(params.totalAmount, 1, 1_000_000_000e18);

        // The cliff time must be either zero or greater than the start time.
        if (cliffTime > 0) {
            cliffTime = boundUint40(cliffTime, params.timestamps.start + 1 seconds, params.timestamps.start + 52 weeks);
        }

        // Bound the end time so that it is always greater than the start time, and the cliff time.
        uint40 endTimeLowerBound = maxOfTwo(params.timestamps.start, cliffTime);
        params.timestamps.end = boundUint40(params.timestamps.end, endTimeLowerBound + 1 seconds, MAX_UNIX_TIMESTAMP);

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierLockup} to spend the assets.
        asset.approve({ spender: address(lockup), value: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = lockup.createWithTimestampsLL(params, cliffTime);

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
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty tranche arrays.
        vm.assume(tranches.length != 0);

        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);
        params.timestamps.start = boundUint40(params.timestamps.start, 1, getBlockTimestamp());

        // Fuzz the tranche timestamps.
        fuzzTrancheTimestamps(tranches, params.timestamps.start);

        // Fuzz the tranche amounts and calculate the total amount.
        (params.totalAmount,) = fuzzTranchedStreamAmounts({
            upperBound: 1_000_000_000e18,
            tranches: tranches,
            brokerFee: params.broker.fee
        });

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierLockup} to spend the assets.
        asset.approve({ spender: address(lockup), value: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        params.timestamps.end = tranches[tranches.length - 1].timestamp;
        uint256 streamId = lockup.createWithTimestampsLT(params, tranches);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }
}
