// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { Broker, LockupLinear } from "src/types/DataTypes.sol";

import { LockupHandler } from "./LockupHandler.t.sol";

/// @title LockupLinearHandler
/// @dev This contract and not {SablierV2LockupLinear} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract LockupLinearHandler is LockupHandler {
    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2LockupLinear public linear;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address admin_, IERC20 asset_, ISablierV2LockupLinear linear_) LockupHandler(admin_, asset_, linear_) {
        linear = linear_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDurationsParams {
        Broker broker;
        bool cancelable;
        LockupLinear.Durations durations;
        address recipient;
        address sender;
        uint128 totalAmount;
    }

    struct CreateWithDurationsVars {
        uint256 streamId;
    }

    function createWithDurations(
        CreateWithDurationsParams memory params
    ) public instrument("createWithDurations") useNewSender(params.sender) {
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.durations.cliff = boundUint40(params.durations.cliff, 1, 1_000);
        params.durations.total = boundUint40(params.durations.total, params.durations.cliff + 1, MAX_UNIX_TIMESTAMP);
        params.totalAmount = boundUint128(params.totalAmount, 1, 1_000_000_000e18);

        // We don't want to fuzz more than a certain number of streams.
        if (streamIds.length > MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow the sender, recipient or broker to be the zero address.
        if (params.sender == address(0) || params.recipient == address(0) || params.broker.addr == address(0)) {
            return;
        }

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(asset), to: params.sender, give: params.totalAmount });

        // Approve the {SablierV2LockupLinear} contract to spend the ERC-20 assets.
        asset.approve({ spender: address(linear), amount: params.totalAmount });

        // Create the stream.
        CreateWithDurationsVars memory vars;
        vars.streamId = linear.createWithDurations({
            sender: params.sender,
            recipient: params.recipient,
            totalAmount: params.totalAmount,
            asset: asset,
            cancelable: params.cancelable,
            durations: params.durations,
            broker: params.broker
        });

        // Store the stream id in the ids array and the reverse mapping.
        streamIds.push(vars.streamId);
        streamIdsToRecipients[vars.streamId] = params.recipient;
        streamIdsToSenders[vars.streamId] = params.sender;

        // Update the last stream id.
        lastStreamId = vars.streamId;
    }

    /// @dev This function exists only to bias the invariant calls toward {createWithDurations}, so that more streams
    /// get created.
    function createWithDurations_Bias(CreateWithDurationsParams memory params) external {
        createWithDurations(params);
    }

    struct CreateWithRangeParams {
        Broker broker;
        bool cancelable;
        LockupLinear.Range range;
        address recipient;
        address sender;
        uint128 totalAmount;
    }

    struct CreateWithRangeVars {
        uint256 streamId;
    }

    function createWithRange(
        CreateWithRangeParams memory params
    ) public instrument("createWithRange") useNewSender(params.sender) {
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.range.start = boundUint40(params.range.start, 0, 1_000);
        params.range.cliff = boundUint40(params.range.cliff, params.range.start, 5_000);
        params.range.end = boundUint40(params.range.end, params.range.cliff + 1, MAX_UNIX_TIMESTAMP);
        params.totalAmount = boundUint128(params.totalAmount, 1, 1_000_000_000e18);

        // We don't want to fuzz more than a certain number of streams.
        if (streamIds.length > MAX_STREAM_COUNT) {
            return;
        }

        // The protocol doesn't allow the sender, recipient or broker to be the zero address.
        if (params.sender == address(0) || params.recipient == address(0) || params.broker.addr == address(0)) {
            return;
        }

        // Mint enough ERC-20 assets to the sender.
        deal({ token: address(asset), to: params.sender, give: params.totalAmount });

        // Approve the {SablierV2LockupLinear} contract to spend the ERC-20 assets.
        asset.approve({ spender: address(linear), amount: params.totalAmount });

        // Create the stream.
        CreateWithRangeVars memory vars;
        vars.streamId = linear.createWithRange({
            sender: params.sender,
            recipient: params.recipient,
            totalAmount: params.totalAmount,
            asset: asset,
            cancelable: params.cancelable,
            range: params.range,
            broker: params.broker
        });

        // Store the stream id in the ids array and the reverse mapping.
        streamIds.push(vars.streamId);
        streamIdsToRecipients[vars.streamId] = params.recipient;
        streamIdsToSenders[vars.streamId] = params.sender;

        // Update the last stream id.
        lastStreamId = vars.streamId;
    }

    /// @dev This function exists only to bias the invariant calls toward {createWithRange}, so that more streams
    /// get created.
    function createWithRange_Bias(CreateWithRangeParams memory params) external {
        createWithRange(params);
    }
}
