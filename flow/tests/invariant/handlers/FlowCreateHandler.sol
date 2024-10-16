// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18 } from "@prb/math/src/UD21x18.sol";

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

    IERC20 public currentToken;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier useFuzzedToken(uint256 tokenIndex) {
        IERC20[] memory tokens = flowStore.getTokens();
        vm.assume(tokenIndex < tokens.length);
        currentToken = tokens[tokenIndex];
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(FlowStore flowStore_, ISablierFlow flow_) BaseHandler(flowStore_, flow_) { }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Struct to prevent stack too deep error.
    struct CreateParams {
        uint128 depositAmount;
        uint256 timeJump;
        uint256 tokenIndex;
        address sender;
        address recipient;
        uint128 ratePerSecond;
        bool transferable;
    }

    function create(CreateParams memory params)
        public
        useFuzzedToken(params.tokenIndex)
        adjustTimestamp(params.timeJump)
        instrument(flow.nextStreamId(), "create")
    {
        _checkParams(params);

        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);

        // Create the stream.
        uint256 streamId = flow.create(
            params.sender, params.recipient, ud21x18(params.ratePerSecond), currentToken, params.transferable
        );

        // Store the stream id and rate per second.
        flowStore.initStreamId(streamId, params.ratePerSecond);
    }

    function createAndDeposit(CreateParams memory params)
        public
        useFuzzedToken(params.tokenIndex)
        adjustTimestamp(params.timeJump)
        instrument(flow.nextStreamId(), "createAndDeposit")
    {
        _checkParams(params);

        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);

        // Calculate the upper bound, based on the token decimals, for the deposit amount.
        uint256 upperBound = getDescaledAmount(1_000_000e18, IERC20Metadata(address(currentToken)).decimals());
        uint256 lowerBound = getDescaledAmount(1e18, IERC20Metadata(address(currentToken)).decimals());

        // Make sure the deposit amount is non-zero and less than values that could cause an overflow.
        vm.assume(params.depositAmount >= lowerBound && params.depositAmount <= upperBound);

        // Mint enough tokens to the Sender.
        deal({
            token: address(currentToken),
            to: params.sender,
            give: currentToken.balanceOf(params.sender) + params.depositAmount
        });

        // Approve {SablierFlow} to spend the tokens.
        currentToken.approve({ spender: address(flow), value: params.depositAmount });

        // Create the stream.
        uint256 streamId = flow.createAndDeposit(
            params.sender,
            params.recipient,
            ud21x18(params.ratePerSecond),
            currentToken,
            params.transferable,
            params.depositAmount
        );

        // Store the stream id and rate per second.
        flowStore.initStreamId(streamId, params.ratePerSecond);

        // Store the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(streamId, currentToken, params.depositAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Check the relevant parameters fuzzed for create.
    function _checkParams(CreateParams memory params) private {
        // The protocol doesn't allow the sender or recipient to be the zero address.
        vm.assume(params.sender != address(0) && params.recipient != address(0));

        // Prevent the contract itself from playing the role of any user.
        vm.assume(params.sender != address(this) && params.recipient != address(this));

        // Reset the caller.
        resetPrank(params.sender);

        uint8 decimals = IERC20Metadata(address(currentToken)).decimals();

        // Calculate the minimum value in scaled version that can be withdrawn for this token.
        uint256 mvt = getScaledAmount(1, decimals);

        // For 18 decimal, check the rate per second is within a realistic range.
        if (decimals == 18) {
            vm.assume(params.ratePerSecond > 0.00001e18 && params.ratePerSecond <= 1e18);
        }
        // For all other decimals, choose the minimum rps such that it takes 100 seconds to stream 1 token.
        else {
            vm.assume(params.ratePerSecond > mvt / 100 && params.ratePerSecond <= 1e18);
        }
    }
}
