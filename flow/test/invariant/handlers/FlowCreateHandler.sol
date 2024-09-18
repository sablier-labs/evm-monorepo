// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";

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

    modifier useFuzzedToken(uint256 tokenIndex) {
        vm.assume(tokenIndex < tokens.length);
        currentToken = tokens[tokenIndex];
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
        uint128 depositAmount;
        uint256 timeJump;
        uint256 tokenIndex;
        address sender;
        address recipient;
        UD21x18 ratePerSecond;
        bool transferable;
    }

    function create(CreateParams memory params)
        public
        checkUsers(params)
        useFuzzedToken(params.tokenIndex)
        adjustTimestamp(params.timeJump)
        instrument(flow.nextStreamId(), "create")
    {
        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);

        // Use a realistic range for the rate per second.
        vm.assume(params.ratePerSecond.unwrap() >= 0.0000000001e18 && params.ratePerSecond.unwrap() <= 10e18);

        // Create the stream.
        uint256 streamId =
            flow.create(params.sender, params.recipient, params.ratePerSecond, currentToken, params.transferable);

        // Store the stream id.
        flowStore.pushStreamId(streamId);
    }

    function createAndDeposit(CreateParams memory params)
        public
        checkUsers(params)
        useFuzzedToken(params.tokenIndex)
        adjustTimestamp(params.timeJump)
        instrument(flow.nextStreamId(), "createAndDeposit")
    {
        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);

        uint8 decimals = IERC20Metadata(address(currentToken)).decimals();

        // Calculate the upper bound, based on the token decimals, for the deposit amount.
        uint128 upperBound = getDenormalizedAmount(1_000_000e18, decimals);

        // Make sure the deposit amount is non-zero and less than values that could cause an overflow.
        vm.assume(params.depositAmount >= 100 && params.depositAmount <= upperBound);

        // Use a realistic range for the rate per second.
        vm.assume(params.ratePerSecond.unwrap() >= 0.0000000001e18 && params.ratePerSecond.unwrap() <= 10e18);

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
            params.ratePerSecond,
            currentToken,
            params.transferable,
            params.depositAmount
        );

        // Store the stream id.
        flowStore.pushStreamId(streamId);

        // Store the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(streamId, currentToken, params.depositAmount);
    }
}
