// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";

import { OpenEndedStore } from "../stores/OpenEndedStore.sol";
import { TimestampStore } from "../stores/TimestampStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract is a complement of {OpenEndedHandler}. The goal is to bias the invariant calls
/// toward the openEnded functions (especially the create stream functions) by creating multiple handlers for
/// the contracts.
contract OpenEndedCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2OpenEnded public openEnded;
    OpenEndedStore public openEndedStore;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        TimestampStore timestampStore_,
        OpenEndedStore openEndedStore_,
        ISablierV2OpenEnded openEnded_
    )
        BaseHandler(asset_, timestampStore_)
    {
        openEndedStore = openEndedStore_;
        openEnded = openEnded_;
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
        if (openEndedStore.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // Bound the stream parameters.
        params.ratePerSecond = uint128(_bound(params.ratePerSecond, 0.0001e18, 1e18));

        // Create the stream.
        asset = asset;
        uint256 streamId =
            openEnded.create(params.sender, params.recipient, params.ratePerSecond, asset, params.isTransferable);

        // Store the stream id.
        openEndedStore.pushStreamId(streamId, params.sender, params.recipient);
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
        if (openEndedStore.lastStreamId() >= MAX_STREAM_COUNT) {
            return;
        }

        // Bound the stream parameters.
        params.ratePerSecond = uint128(_bound(params.ratePerSecond, 0.0001e18, 1e18));
        depositAmount = uint128(_bound(depositAmount, 100e18, 1_000_000_000e18));

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: params.sender, give: asset.balanceOf(params.sender) + depositAmount });

        // Approve {SablierV2OpenEnded} to spend the assets.
        asset.approve({ spender: address(openEnded), value: depositAmount });

        // Create the stream.
        uint256 streamId = openEnded.createAndDeposit(
            params.sender, params.recipient, params.ratePerSecond, asset, params.isTransferable, depositAmount
        );

        // Store the stream id.
        openEndedStore.pushStreamId(streamId, params.sender, params.recipient);

        // Store the deposited amount.
        openEndedStore.updateStreamDepositedAmountsSum(streamId, depositAmount);
    }
}
