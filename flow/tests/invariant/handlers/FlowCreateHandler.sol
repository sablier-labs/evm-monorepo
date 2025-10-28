// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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

    uint256 internal streamId;

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
        uint40 startTime;
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
        streamId = flow.create(
            params.sender,
            params.recipient,
            ud21x18(params.ratePerSecond),
            params.startTime,
            currentToken,
            params.transferable
        );

        // Store the stream id and rate per second.
        flowStore.initStreamId(streamId, params.ratePerSecond, params.startTime, getBlockTimestamp());
    }

    /// @dev We assume a start time earlier than the current block timestamp to avoid having too many PENDING
    /// streams. We chose this function because the deposit allows calls to other functions as well (refund and
    /// withdraw).
    function createAndDeposit(CreateParams memory params)
        public
        useFuzzedToken(params.tokenIndex)
        adjustTimestamp(params.timeJump)
        instrument(flow.nextStreamId(), "createAndDeposit")
    {
        _checkParams(params);

        vm.assume(flowStore.lastStreamId() < MAX_STREAM_COUNT);
        params.startTime = boundUint40(params.startTime, 1, getBlockTimestamp());

        // Bound the deposit amount.
        params.depositAmount = boundDepositAmount({
            amount: params.depositAmount,
            lowerBound18D: 1e18,
            upperBound18D: 1_000_000e18,
            decimals: IERC20Metadata(address(currentToken)).decimals()
        });

        // Mint enough tokens to the Sender.
        deal({
            token: address(currentToken),
            to: params.sender,
            give: currentToken.balanceOf(params.sender) + params.depositAmount
        });

        // Approve {SablierFlow} to spend the tokens.
        currentToken.approve({ spender: address(flow), value: params.depositAmount });

        // Create the stream.
        streamId = flow.createAndDeposit(
            params.sender,
            params.recipient,
            ud21x18(params.ratePerSecond),
            params.startTime,
            currentToken,
            params.transferable,
            params.depositAmount
        );

        // Store the stream id and rate per second.
        flowStore.initStreamId(streamId, params.ratePerSecond, params.startTime, getBlockTimestamp());

        // Store the deposit totals.
        flowStore.updateTotalDeposits(streamId, currentToken, params.depositAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Check the relevant parameters fuzzed for create.
    function _checkParams(CreateParams memory params) private {
        // Make sure the sender and recipient are not the zero address or the contract itself.
        params.sender = fuzzAddrWithExclusion(params.sender, address(this));
        params.recipient = fuzzAddrWithExclusion(params.recipient, address(this));

        // Change the caller.
        setMsgSender(params.sender);

        uint8 decimals = IERC20Metadata(address(currentToken)).decimals();

        // For 18 decimal, check the rate per second is within a realistic range.
        if (decimals == 18) {
            params.ratePerSecond = boundUint128(params.ratePerSecond, 0.00001e18, 1e18);
        }
        // For all other decimals, choose the minimum rps such that it takes 100 seconds to stream 1 token.
        else {
            uint256 mvt = getScaledAmount({ amount: 1, decimals: decimals });
            params.ratePerSecond = boundUint128(params.ratePerSecond, uint128(mvt / 100), 1e18);
        }
    }
}
