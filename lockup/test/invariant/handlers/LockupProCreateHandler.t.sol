// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";
import { Broker, LockupPro } from "src/types/DataTypes.sol";

import { BaseHandler } from "./BaseHandler.t.sol";
import { LockupHandlerStore } from "./LockupHandlerStore.t.sol";

/// @title LockupProCreateHandler
/// @dev This contract is a complement of {LockupProHandler}. The goal is to bias the invariant calls
/// toward the lockup functions by creating multiple handlers for the lockup contracts.
contract LockupProCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_STREAM_COUNT = 100;

    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public asset;
    ISablierV2Comptroller public comptroller;
    ISablierV2LockupPro public pro;
    LockupHandlerStore public store;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        ISablierV2Comptroller comptroller_,
        ISablierV2LockupPro pro_,
        LockupHandlerStore store_
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
        uint40 delta0;
        uint40 delta1;
        address recipient;
        address sender;
        uint128 totalAmount;
    }

    struct CreateWithDeltasVars {
        uint256 streamId;
        uint40[] deltas;
        UD60x18 protocolFee;
        uint128 depositAmount;
        LockupPro.Segment[] segments;
    }

    function createWithDeltas(
        CreateWithDeltasParams memory params
    ) public instrument("createWithDeltas") useNewSender(params.sender) {
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.delta0 = boundUint40(params.delta0, 1, 100);
        params.delta1 = boundUint40(params.delta1, 1, MAX_UNIX_TIMESTAMP - uint40(block.timestamp) - params.delta0);
        params.totalAmount = boundUint128(params.totalAmount, 1, 1_000_000_000e18);

        // We don't want to fuzz more than a certain number of streams.
        if (store.lastStreamId() > MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow the sender, recipient or broker to be the zero address.
        if (params.sender == address(0) || params.recipient == address(0) || params.broker.addr == address(0)) {
            return;
        }

        // Create the deltas array.
        CreateWithDeltasVars memory vars;
        vars.deltas = Solarray.uint40s(params.delta0, params.delta1);

        // Adjust the segment milestones to match the fuzzed deltas.
        vars.segments = DEFAULT_SEGMENTS;
        vars.segments[0].milestone = uint40(block.timestamp) + params.delta0;
        vars.segments[1].milestone = vars.segments[0].milestone + params.delta1;

        // Calculate the deposit amount.
        vars.depositAmount = calculateDepositAmount(params.totalAmount, vars.protocolFee, params.broker.fee);

        // Adjust the segment amounts based on the fuzzed deposit amount.
        adjustSegmentAmounts(vars.segments, vars.depositAmount);

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(asset), to: params.sender, give: params.totalAmount });

        // Approve the {SablierV2LockupPro} contract to spend the ERC-20 assets.
        asset.approve({ spender: address(pro), amount: params.totalAmount });

        // Create the stream.
        vars.streamId = pro.createWithDeltas({
            sender: params.sender,
            recipient: params.recipient,
            totalAmount: params.totalAmount,
            segments: vars.segments,
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
        uint128 totalAmount;
        address recipient;
        address sender;
        uint40 startTime;
    }

    struct CreateWithMilestonesVars {
        uint128 depositAmount;
        UD60x18 protocolFee;
        LockupPro.Segment[] segments;
        uint256 streamId;
    }

    function createWithMilestones(
        CreateWithMilestonesParams memory params
    ) public instrument("createWithMilestones") useNewSender(params.sender) {
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.startTime = boundUint40(params.startTime, 0, DEFAULT_SEGMENTS[0].milestone - 1);
        params.totalAmount = boundUint128(params.totalAmount, 1, 1_000_000_000e18);

        // We don't want to fuzz more than a certain number of streams.
        if (store.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow the sender, recipient or broker to be the zero address.
        if (params.sender == address(0) || params.recipient == address(0) || params.broker.addr == address(0)) {
            return;
        }

        // Get the current protocol fee.
        CreateWithMilestonesVars memory vars;
        vars.protocolFee = comptroller.getProtocolFee(asset);

        // Calculate the deposit amount.
        vars.depositAmount = calculateDepositAmount(params.totalAmount, vars.protocolFee, params.broker.fee);

        // Adjust the segment amounts based on the fuzzed deposit amount.
        vars.segments = DEFAULT_SEGMENTS;
        adjustSegmentAmounts(vars.segments, vars.depositAmount);

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(asset), to: params.sender, give: params.totalAmount });

        // Approve the {SablierV2LockupPro} contract to spend the ERC-20 assets.
        asset.approve({ spender: address(pro), amount: params.totalAmount });

        // Create the stream.
        vars.streamId = pro.createWithMilestones({
            sender: params.sender,
            recipient: params.recipient,
            totalAmount: params.totalAmount,
            segments: vars.segments,
            asset: asset,
            cancelable: params.cancelable,
            startTime: params.startTime,
            broker: params.broker
        });

        // Store the stream id.
        store.pushStreamId(vars.streamId, params.sender, params.recipient);
    }
}
