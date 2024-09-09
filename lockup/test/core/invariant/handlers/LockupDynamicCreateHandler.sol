// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockupDynamic } from "src/core/interfaces/ISablierLockupDynamic.sol";
import { LockupDynamic } from "src/core/types/DataTypes.sol";

import { LockupStore } from "../stores/LockupStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract is a complement of {LockupDynamicHandler}. The goal is to bias the invariant calls toward the
/// lockup functions (especially the create stream functions) by creating multiple handlers for the Lockup contracts.
contract LockupDynamicCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierLockupDynamic public lockupDynamic;
    LockupStore public lockupStore;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, LockupStore lockupStore_, ISablierLockupDynamic lockupDynamic_) BaseHandler(asset_) {
        lockupStore = lockupStore_;
        lockupDynamic = lockupDynamic_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDurations(
        uint256 timeJumpSeed,
        LockupDynamic.CreateWithDurations memory params
    )
        public
        instrument("createWithDurations")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty segment arrays.
        vm.assume(params.segments.length != 0);

        // Bound the broker fee.
        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);

        // Fuzz the durations.
        fuzzSegmentDurations(params.segments);

        // Fuzz the segment amounts and calculate the total amount.
        (params.totalAmount,) = fuzzDynamicStreamAmounts({
            upperBound: 1_000_000_000e18,
            segments: params.segments,
            brokerFee: params.broker.fee
        });

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierLockupDynamic} to spend the assets.
        asset.approve({ spender: address(lockupDynamic), value: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = lockupDynamic.createWithDurations(params);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithTimestamps(
        uint256 timeJumpSeed,
        LockupDynamic.CreateWithTimestamps memory params
    )
        public
        instrument("createWithTimestamps")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        vm.assume(lockupStore.lastStreamId() <= MAX_STREAM_COUNT);

        // The protocol doesn't allow empty segment arrays.
        vm.assume(params.segments.length != 0);

        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);
        params.startTime = boundUint40(params.startTime, 1, getBlockTimestamp());

        // Fuzz the segment timestamps.
        fuzzSegmentTimestamps(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the total amount.
        (params.totalAmount,) = fuzzDynamicStreamAmounts({
            upperBound: 1_000_000_000e18,
            segments: params.segments,
            brokerFee: params.broker.fee
        });

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierLockupDynamic} to spend the assets.
        asset.approve({ spender: address(lockupDynamic), value: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = lockupDynamic.createWithTimestamps(params);

        // Store the stream ID.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }
}
