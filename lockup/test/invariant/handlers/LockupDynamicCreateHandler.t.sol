// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { BaseHandler } from "./BaseHandler.t.sol";
import { LockupHandlerStorage } from "./LockupHandlerStorage.t.sol";

/// @title LockupDynamicCreateHandler
/// @dev This contract is a complement of {LockupDynamicHandler}. The goal is to bias the invariant calls
/// toward the lockup functions (especially the create stream functions) by creating multiple handlers for
/// the lockup contracts.
contract LockupDynamicCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_STREAM_COUNT = 100;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public asset;
    ISablierV2Comptroller public comptroller;
    ISablierV2LockupDynamic public dynamic;
    LockupHandlerStorage public store;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        ISablierV2Comptroller comptroller_,
        ISablierV2LockupDynamic dynamic_,
        LockupHandlerStorage store_
    ) {
        asset = asset_;
        comptroller = comptroller_;
        dynamic = dynamic_;
        store = store_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier useNewSender(address sender) {
        vm.startPrank(sender);
        _;
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDeltas(LockupDynamic.CreateWithDeltas memory params)
        public
        checkUsers(params.sender, params.recipient, params.broker.account)
        instrument("createWithDeltas")
        useNewSender(params.sender)
    {
        // We don't want to fuzz more than a certain number of streams.
        if (store.lastStreamId() > MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow empty segment arrays.
        if (params.segments.length == 0) {
            return;
        }

        // Bound the broker fee.
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);

        // Fuzz the deltas.
        fuzzSegmentDeltas(params.segments);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (params.totalAmount,) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: 1_000_000_000e18,
            segments: params.segments,
            protocolFee: comptroller.getProtocolFee(asset),
            brokerFee: params.broker.fee
        });

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierV2LockupDynamic} to spend the ERC-20 assets.
        asset.approve({ spender: address(dynamic), amount: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = dynamic.createWithDeltas(params);

        // Store the stream id.
        store.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithMilestones(LockupDynamic.CreateWithMilestones memory params)
        public
        checkUsers(params.sender, params.recipient, params.broker.account)
        instrument("createWithMilestones")
        useNewSender(params.sender)
    {
        // We don't want to fuzz more than a certain number of streams.
        if (store.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow empty segment arrays.
        if (params.segments.length == 0) {
            return;
        }

        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, DEFAULT_START_TIME);

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (params.totalAmount,) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: 1_000_000_000e18,
            segments: params.segments,
            protocolFee: comptroller.getProtocolFee(asset),
            brokerFee: params.broker.fee
        });

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierV2LockupDynamic} to spend the ERC-20 assets.
        asset.approve({ spender: address(dynamic), amount: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = dynamic.createWithMilestones(params);

        // Store the stream id.
        store.pushStreamId(streamId, params.sender, params.recipient);
    }
}
