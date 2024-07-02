// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { FlowStore } from "../stores/FlowStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract is a complement of {FlowHandler}. The goal is to bias the invariant calls
/// toward the Flow functions (especially the create stream functions) by creating multiple handlers for
/// the contracts.
contract FlowCreateHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Default ERC20 assets used for testing.
    IERC20[] public assets;
    IERC20 public currentAsset;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier useFuzzedAsset(uint256 assetIndexSeed) {
        assetIndexSeed = _bound(assetIndexSeed, 0, assets.length - 1);
        currentAsset = assets[assetIndexSeed];
        _;
    }

    modifier checkUsers(CreateParams memory params) {
        // The protocol doesn't allow the sender or recipient to be the zero address.
        vm.assume(params.sender != address(0) && params.recipient != address(0));

        // Prevent the contract itself from playing the role of any user.
        vm.assume(params.sender != address(this) && params.recipient != address(this));

        // Reset the caller.
        resetPrank(params.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(FlowStore flowStore_, ISablierFlow flow_, IERC20[] memory assets_) BaseHandler(flowStore_, flow_) {
        for (uint256 i = 0; i < assets_.length; ++i) {
            assets.push(assets_[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Struct to prevent stack too deep error.
    struct CreateParams {
        uint256 timeJumpSeed;
        uint256 assetIndexSeed;
        address sender;
        address recipient;
        uint128 ratePerSecond;
        bool isTransferable;
    }

    function create(CreateParams memory params)
        public
        instrument("create")
        checkUsers(params)
        useFuzzedAsset(params.assetIndexSeed)
        adjustTimestamp(params.timeJumpSeed)
    {
        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);

        // Bound the stream parameters.
        params.ratePerSecond = uint128(_bound(params.ratePerSecond, 0.0001e18, 1e18));

        // Create the stream.
        uint256 streamId =
            flow.create(params.sender, params.recipient, params.ratePerSecond, currentAsset, params.isTransferable);

        // Store the stream id.
        flowStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createAndDeposit(
        CreateParams memory params,
        uint128 transferAmount
    )
        public
        instrument("createAndDeposit")
        checkUsers(params)
        useFuzzedAsset(params.assetIndexSeed)
        adjustTimestamp(params.timeJumpSeed)
    {
        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);

        uint8 decimals = IERC20Metadata(address(currentAsset)).decimals();

        // Calculate the upper bound, based on the asset decimals, for the transfer amount.
        uint128 upperBound = getTransferAmount(1_000_000e18, decimals);

        // Bound the stream parameters.
        params.ratePerSecond = uint128(_bound(params.ratePerSecond, 0.0001e18, 1e18));
        transferAmount = uint128(_bound(transferAmount, 100, upperBound));

        // Mint enough assets to the Sender.
        deal({
            token: address(currentAsset),
            to: params.sender,
            give: currentAsset.balanceOf(params.sender) + transferAmount
        });

        // Approve {SablierFlow} to spend the assets.
        currentAsset.approve({ spender: address(flow), value: transferAmount });

        // Create the stream.
        uint256 streamId = flow.createAndDeposit(
            params.sender, params.recipient, params.ratePerSecond, currentAsset, params.isTransferable, transferAmount
        );

        // Store the stream id.
        flowStore.pushStreamId(streamId, params.sender, params.recipient);

        uint128 normalizedAmount = getNormalizedAmount(transferAmount, decimals);

        // Store the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(streamId, normalizedAmount);
    }
}
