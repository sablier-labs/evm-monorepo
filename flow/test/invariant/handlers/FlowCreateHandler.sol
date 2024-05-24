// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { FlowStore } from "../stores/FlowStore.sol";
import { TimestampStore } from "../stores/TimestampStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract is a complement of {FlowHandler}. The goal is to bias the invariant calls
/// toward the Flow functions (especially the create stream functions) by creating multiple handlers for
/// the contracts.
contract FlowCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierFlow public flow;
    FlowStore public flowStore;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        TimestampStore timestampStore_,
        FlowStore flowStore_,
        ISablierFlow flow_
    )
        BaseHandler(asset_, timestampStore_)
    {
        flowStore = flowStore_;
        flow = flow_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Struct to prevent stack too deep error.
    struct CreateParams {
        uint256 timeJumpSeed;
        address sender;
        address recipient;
        uint128 ratePerSecond;
        bool isTransferable;
    }

    function create(CreateParams memory params)
        public
        instrument("createAndDeposit")
        adjustTimestamp(params.timeJumpSeed)
        checkUsers(params.sender, params.recipient)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        if (flowStore.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // Bound the stream parameters.
        params.ratePerSecond = uint128(_bound(params.ratePerSecond, 0.0001e18, 1e18));

        // Create the stream.
        asset = asset;
        uint256 streamId =
            flow.create(params.sender, params.recipient, params.ratePerSecond, asset, params.isTransferable);

        // Store the stream id.
        flowStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createAndDeposit(
        CreateParams memory params,
        uint128 depositAmount
    )
        public
        instrument("createAndDeposit")
        adjustTimestamp(params.timeJumpSeed)
        checkUsers(params.sender, params.recipient)
        useNewSender(params.sender)
    {
        // We don't want to create more than a certain number of streams.
        if (flowStore.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // Bound the stream parameters.
        params.ratePerSecond = uint128(_bound(params.ratePerSecond, 0.0001e18, 1e18));
        depositAmount = uint128(_bound(depositAmount, 100e18, 1_000_000_000e18));

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + depositAmount });

        // Approve {SablierFlow} to spend the assets.
        asset.approve({ spender: address(flow), value: depositAmount });

        // Create the stream.
        uint256 streamId = flow.createAndDeposit(
            params.sender, params.recipient, params.ratePerSecond, asset, params.isTransferable, depositAmount
        );

        // Store the stream id.
        flowStore.pushStreamId(streamId, params.sender, params.recipient);

        // Store the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(streamId, depositAmount);
    }
}
