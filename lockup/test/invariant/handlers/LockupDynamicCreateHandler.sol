// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { LockupStore } from "../stores/LockupStore.sol";
import { TimestampStore } from "../stores/TimestampStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract is a complement of {LockupDynamicHandler}. The goal is to bias the invariant calls
/// toward the lockup functions (especially the create stream functions) by creating multiple handlers for
/// the lockup contracts.
contract LockupDynamicCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller public comptroller;
    ISablierV2LockupDynamic public lockupDynamic;
    LockupStore public lockupStore;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        TimestampStore timestampStore_,
        LockupStore lockupStore_,
        ISablierV2Comptroller comptroller_,
        ISablierV2LockupDynamic lockupDynamic_
    )
        BaseHandler(asset_, timestampStore_)
    {
        lockupStore = lockupStore_;
        comptroller = comptroller_;
        lockupDynamic = lockupDynamic_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDeltas(
        uint256 timeJumpSeed,
        LockupDynamic.CreateWithDeltas memory params
    )
        public
        instrument("createWithDeltas")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        if (lockupStore.lastStreamId() > MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow empty segment arrays.
        if (params.segments.length == 0) {
            return;
        }

        // Bound the broker fee.
        params.broker.fee = _bound(params.broker.fee, 0, MAX_FEE);

        // Fuzz the deltas.
        fuzzSegmentDeltas(params.segments);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (params.totalAmount,) = fuzzDynamicStreamAmounts({
            upperBound: 1_000_000_000e18,
            segments: params.segments,
            protocolFee: comptroller.protocolFees(asset),
            brokerFee: params.broker.fee
        });

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierV2LockupDynamic} to spend the assets.
        asset.approve({ spender: address(lockupDynamic), amount: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = lockupDynamic.createWithDeltas(params);

        // Store the stream id.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithMilestones(
        uint256 timeJumpSeed,
        LockupDynamic.CreateWithMilestones memory params
    )
        public
        instrument("createWithMilestones")
        adjustTimestamp(timeJumpSeed)
        checkUsers(params.sender, params.recipient, params.broker.account)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        if (lockupStore.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow empty segment arrays.
        if (params.segments.length == 0) {
            return;
        }

        params.broker.fee = _bound(params.broker.fee, 0, MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, getBlockTimestamp());

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (params.totalAmount,) = fuzzDynamicStreamAmounts({
            upperBound: 1_000_000_000e18,
            segments: params.segments,
            protocolFee: comptroller.protocolFees(asset),
            brokerFee: params.broker.fee
        });

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierV2LockupDynamic} to spend the assets.
        asset.approve({ spender: address(lockupDynamic), amount: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = lockupDynamic.createWithMilestones(params);

        // Store the stream id.
        lockupStore.pushStreamId(streamId, params.sender, params.recipient);
    }
}
