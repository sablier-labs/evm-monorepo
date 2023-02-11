// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";
import { Broker, Lockup, LockupPro } from "src/types/DataTypes.sol";

import { BaseHandler } from "./BaseHandler.t.sol";
import { LockupHandlerStorage } from "./LockupHandlerStorage.t.sol";

/// @title LockupProCreateHandler
/// @dev This contract is a complement of {LockupProHandler}. The goal is to bias the invariant calls
/// toward the lockup functions by creating multiple handlers for the lockup contracts.
contract LockupProCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_STREAM_COUNT = 100;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public asset;
    LockupHandlerStorage public store;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        ISablierV2Comptroller comptroller_,
        ISablierV2LockupPro pro_,
        LockupHandlerStorage store_
    ) {
        asset = asset_;
        comptroller = comptroller_;
        pro = pro_;
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
                                     FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDeltasParams {
        Broker broker;
        bool cancelable;
        address recipient;
        LockupPro.Segment[] segments;
        address sender;
    }

    struct CreateWithDeltasVars {
        uint256 streamId;
        uint40[] deltas;
        uint128 totalAmount;
    }

    function createWithDeltas(
        CreateWithDeltasParams memory params
    ) public instrument("createWithDeltas") useNewSender(params.sender) {
        // We don't want to fuzz more than a certain number of streams.
        if (store.lastStreamId() > MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow the sender, recipient or broker to be the zero address.
        if (params.sender == address(0) || params.recipient == address(0) || params.broker.addr == address(0)) {
            return;
        }

        // The protocol doesn't allow empty segments.
        if (params.segments.length == 0) {
            return;
        }

        // Bound the broker fee.
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);

        // Fuzz the deltas and update the segment milestones.
        CreateWithDeltasVars memory vars;
        vars.deltas = fuzzSegmentDeltas(params.segments);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (vars.totalAmount, ) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: 1_000_000_000e18,
            segments: params.segments,
            protocolFee: comptroller.getProtocolFee(asset),
            brokerFee: params.broker.fee
        });

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(asset), to: params.sender, give: vars.totalAmount });

        // Approve the {SablierV2LockupPro} contract to spend the ERC-20 assets.
        asset.approve({ spender: address(pro), amount: vars.totalAmount });

        // Create the stream.
        vars.streamId = pro.createWithDeltas({
            sender: params.sender,
            recipient: params.recipient,
            totalAmount: vars.totalAmount,
            segments: params.segments,
            asset: asset,
            cancelable: params.cancelable,
            deltas: vars.deltas,
            broker: params.broker
        });

        // Store the stream id.
        store.pushStreamId(vars.streamId, params.sender, params.recipient);
    }

    struct CreateWithMilestonesParams {
        Broker broker;
        bool cancelable;
        address recipient;
        LockupPro.Segment[] segments;
        address sender;
        uint40 startTime;
    }

    struct CreateWithMilestonesVars {
        uint128 depositAmount;
        uint256 streamId;
        uint128 totalAmount;
    }

    function createWithMilestones(
        CreateWithMilestonesParams memory params
    ) public instrument("createWithMilestones") useNewSender(params.sender) {
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, DEFAULT_START_TIME);

        // We don't want to fuzz more than a certain number of streams.
        if (store.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow the sender, recipient or broker to be the zero address.
        if (params.sender == address(0) || params.recipient == address(0) || params.broker.addr == address(0)) {
            return;
        }

        // The protocol doesn't allow empty segments.
        if (params.segments.length == 0) {
            return;
        }

        // Fuzz the segment milestones.
        fuzzSegmentMilestones(params.segments, params.startTime);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        CreateWithMilestonesVars memory vars;
        (vars.totalAmount, ) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: 1_000_000_000e18,
            segments: params.segments,
            protocolFee: comptroller.getProtocolFee(asset),
            brokerFee: params.broker.fee
        });

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(asset), to: params.sender, give: vars.totalAmount });

        // Approve the {SablierV2LockupPro} contract to spend the ERC-20 assets.
        asset.approve({ spender: address(pro), amount: vars.totalAmount });

        // Create the stream.
        vars.streamId = pro.createWithMilestones({
            sender: params.sender,
            recipient: params.recipient,
            totalAmount: vars.totalAmount,
            segments: params.segments,
            asset: asset,
            cancelable: params.cancelable,
            startTime: params.startTime,
            broker: params.broker
        });

        // Store the stream id.
        store.pushStreamId(vars.streamId, params.sender, params.recipient);
    }
}
