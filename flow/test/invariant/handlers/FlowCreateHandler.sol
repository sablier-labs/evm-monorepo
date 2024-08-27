// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    /// @dev Default ERC-20 tokens used for testing.
    IERC20[] public tokens;
    IERC20 public currentToken;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier useFuzzedToken(uint256 tokenIndexSeed) {
        tokenIndexSeed = _bound(tokenIndexSeed, 0, tokens.length - 1);
        currentToken = tokens[tokenIndexSeed];
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

    constructor(FlowStore flowStore_, ISablierFlow flow_, IERC20[] memory tokens_) BaseHandler(flowStore_, flow_) {
        for (uint256 i = 0; i < tokens_.length; ++i) {
            tokens.push(tokens_[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Struct to prevent stack too deep error.
    struct CreateParams {
        uint256 timeJumpSeed;
        uint256 tokenIndexSeed;
        address sender;
        address recipient;
        uint128 ratePerSecond;
        bool transferable;
    }

    function create(
        CreateParams memory params
    )
        public
        instrument("create")
        checkUsers(params)
        useFuzzedToken(params.tokenIndexSeed)
        adjustTimestamp(params.timeJumpSeed)
    {
        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);

        // Bound the stream parameters.
        params.ratePerSecond = boundRatePerSecond(params.ratePerSecond);

        // Create the stream.
        uint256 streamId =
            flow.create(params.sender, params.recipient, params.ratePerSecond, currentToken, params.transferable);

        // Store the stream id.
        flowStore.pushStreamId(streamId, params.sender, params.recipient);
    }

    function createAndDeposit(
        CreateParams memory params,
        uint128 depositAmount
    )
        public
        instrument("createAndDeposit")
        checkUsers(params)
        useFuzzedToken(params.tokenIndexSeed)
        adjustTimestamp(params.timeJumpSeed)
    {
        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);

        uint8 decimals = IERC20Metadata(address(currentToken)).decimals();

        // Calculate the upper bound, based on the token decimals, for the deposit amount.
        uint128 upperBound = getDenormalizedAmount(1_000_000e18, decimals);

        // Bound the stream parameters.
        params.ratePerSecond = boundRatePerSecond(params.ratePerSecond);
        depositAmount = uint128(_bound(depositAmount, 100, upperBound));

        // Mint enough tokens to the Sender.
        deal({
            token: address(currentToken),
            to: params.sender,
            give: currentToken.balanceOf(params.sender) + depositAmount
        });

        // Approve {SablierFlow} to spend the tokens.
        currentToken.approve({ spender: address(flow), value: depositAmount });

        // Create the stream.
        uint256 streamId = flow.createAndDeposit(
            params.sender, params.recipient, params.ratePerSecond, currentToken, params.transferable, depositAmount
        );

        // Store the stream id.
        flowStore.pushStreamId(streamId, params.sender, params.recipient);

        // Store the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(streamId, depositAmount);
    }
}
