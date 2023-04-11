// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { Broker, LockupLinear } from "src/types/DataTypes.sol";

import { BaseHandler } from "./BaseHandler.t.sol";
import { LockupHandlerStorage } from "./LockupHandlerStorage.t.sol";

/// @title LockupLinearCreateHandler
/// @dev This contract is a complement of {LockupLinearHandler}. The goal is to bias the invariant calls
/// toward the lockup functions (especially the create stream functions) by creating multiple handlers for
/// the lockup contracts.
contract LockupLinearCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_STREAM_COUNT = 100;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public asset;
    ISablierV2LockupLinear public linear;
    LockupHandlerStorage public store;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, ISablierV2LockupLinear linear_, LockupHandlerStorage store_) {
        asset = asset_;
        linear = linear_;
        store = store_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDurations(LockupLinear.CreateWithDurations memory params)
        public
        checkUsers(params.sender, params.recipient, params.broker.account)
        instrument("createWithDurations")
        useNewSender(params.sender)
    {
        // We don't want to fuzz more than a certain number of streams.
        if (store.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // Bound the stream parameters.
        params.broker.fee = bound(params.broker.fee, 0, MAX_FEE);
        params.durations.cliff = boundUint40(params.durations.cliff, 1, DEFAULT_CLIFF_DURATION);
        params.durations.total = boundUint40(params.durations.total, params.durations.cliff + 1, MAX_UNIX_TIMESTAMP);
        params.totalAmount = boundUint128(params.totalAmount, 1, 1_000_000_000e18);

        // Mint enough assets to the sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierV2LockupLinear} to spend the assets.
        asset.approve({ spender: address(linear), amount: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = linear.createWithDurations(params);

        // Store the stream id.
        store.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createWithRange(LockupLinear.CreateWithRange memory params)
        public
        checkUsers(params.sender, params.recipient, params.broker.account)
        instrument("createWithRange")
        useNewSender(params.sender)
    {
        // We don't want to fuzz more than a certain number of streams.
        if (store.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        uint40 currentTime = getBlockTimestamp();
        params.broker.fee = bound(params.broker.fee, 0, MAX_FEE);
        params.range.start = boundUint40(params.range.start, 0, currentTime);
        params.range.cliff = boundUint40(params.range.cliff, params.range.start, params.range.start + 52 weeks);
        // Fuzz the end time so that it is always greater than both the current time and the cliff time.
        params.range.end = boundUint40(
            params.range.end,
            (params.range.cliff <= currentTime ? currentTime : params.range.cliff) + 1,
            MAX_UNIX_TIMESTAMP
        );
        params.totalAmount = boundUint128(params.totalAmount, 1, 1_000_000_000e18);

        // Mint enough assets to the sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + params.totalAmount });

        // Approve {SablierV2LockupLinear} to spend the assets.
        asset.approve({ spender: address(linear), amount: params.totalAmount });

        // Create the stream.
        params.asset = asset;
        uint256 streamId = linear.createWithRange(params);

        // Store the stream id.
        store.pushStreamId(streamId, params.sender, params.recipient);
    }
}
