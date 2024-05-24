// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { FlowStore } from "../stores/FlowStore.sol";
import { TimestampStore } from "../stores/TimestampStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

contract FlowHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierFlow public flow;
    FlowStore public flowStore;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal currentRecipient;
    address internal currentSender;
    uint256 internal currentStreamId;

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
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Picks a random stream from the store.
    /// @param streamIndexSeed A fuzzed value needed for picking the random stream.
    modifier useFuzzedStream(uint256 streamIndexSeed) {
        uint256 lastStreamId = flowStore.lastStreamId();
        if (lastStreamId == 0) {
            return;
        }
        uint256 fuzzedStreamId = _bound(streamIndexSeed, 0, lastStreamId - 1);
        currentStreamId = flowStore.streamIds(fuzzedStreamId);
        _;
    }

    modifier useFuzzedStreamRecipient() {
        uint256 lastStreamId = flowStore.lastStreamId();
        currentRecipient = flowStore.recipients(currentStreamId);
        resetPrank(currentRecipient);
        _;
    }

    modifier useFuzzedStreamSender() {
        uint256 lastStreamId = flowStore.lastStreamId();
        currentSender = flowStore.senders(currentStreamId);
        resetPrank(currentSender);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    SABLIER-FLOW
    //////////////////////////////////////////////////////////////////////////*/

    function adjustRatePerSecond(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 newRatePerSecond
    )
        external
        instrument("adjustRatePerSecond")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
    {
        // Only non paused streams can have their rate per second adjusted.
        if (flow.isPaused(currentStreamId)) {
            return;
        }

        // Bound the rate per second.
        newRatePerSecond = uint128(_bound(newRatePerSecond, 0.0001e18, 1e18));

        // The rate per second must be different from the current rate per second.
        if (newRatePerSecond == flow.getRatePerSecond(currentStreamId)) {
            newRatePerSecond += 1;
        }

        // Adjust the rate per second.
        flow.adjustRatePerSecond(currentStreamId, newRatePerSecond);
    }

    function pause(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed
    )
        external
        instrument("pause")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
    {
        // Paused streams cannot be paused again.
        if (flow.isPaused(currentStreamId)) {
            return;
        }

        // Pause the stream.
        flow.pause(currentStreamId);
    }

    function deposit(
        uint256 streamIndexSeed,
        uint128 depositAmount
    )
        external
        instrument("deposit")
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
    {
        // Bound the deposit amount.
        depositAmount = uint128(_bound(depositAmount, 100e18, 1_000_000_000e18));

        // Mint enough assets to the Sender.
        address sender = flowStore.senders(currentStreamId);
        deal({ token: address(asset), to: sender, give: asset.balanceOf(sender) + depositAmount });

        // Approve {SablierFlow} to spend the assets.
        asset.approve({ spender: address(flow), value: depositAmount });

        // Deposit into the stream.
        flow.deposit({ streamId: currentStreamId, amount: depositAmount });

        // Store the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(currentStreamId, depositAmount);
    }

    function refundFromStream(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 refundAmount
    )
        external
        instrument("refundFromStream")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
    {
        // The protocol doesn't allow zero refund amounts.
        uint128 refundableAmount = flow.refundableAmountOf(currentStreamId);
        if (refundableAmount == 0) {
            return;
        }

        // Bound the refund amount so that it is not zero.
        refundAmount = uint128(_bound(refundAmount, 1, refundableAmount));

        // Refund from stream.
        flow.refundFromStream(currentStreamId, refundableAmount);

        // Store the deposited amount.
        flowStore.updateStreamExtractedAmountsSum(currentStreamId, refundAmount);
    }

    function restartStream(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 ratePerSecond
    )
        external
        instrument("restartStream")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
    {
        // Only paused streams can be restarted.
        if (!flow.isPaused(currentStreamId)) {
            return;
        }

        // Bound the stream parameter.
        ratePerSecond = uint128(_bound(ratePerSecond, 0.0001e18, 1e18));

        // Restart the stream.
        flow.restartStream(currentStreamId, ratePerSecond);
    }

    function restartStreamAndDeposit(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 ratePerSecond,
        uint128 depositAmount
    )
        external
        instrument("restartStreamAndDeposit")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
    {
        // Only paused streams can be restarted.
        if (!flow.isPaused(currentStreamId)) {
            return;
        }

        // Bound the stream parameter.
        ratePerSecond = uint128(_bound(ratePerSecond, 0.0001e18, 1e18));
        depositAmount = uint128(_bound(depositAmount, 100e18, 1_000_000_000e18));

        // Mint enough assets to the Sender.
        address sender = flowStore.senders(currentStreamId);
        deal({ token: address(asset), to: sender, give: asset.balanceOf(sender) + depositAmount });

        // Approve {SablierFlow} to spend the assets.
        asset.approve({ spender: address(flow), value: depositAmount });

        // Restart the stream.
        flow.restartStreamAndDeposit(currentStreamId, ratePerSecond, depositAmount);

        // Store the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(currentStreamId, depositAmount);
    }

    function withdrawAt(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        address to,
        uint40 time
    )
        external
        instrument("withdrawAt")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
    {
        // The protocol doesn't allow the withdrawal address to be the zero address.
        if (to == address(0)) {
            return;
        }

        // If the balance and the remaining amount are zero, there is nothing to withdraw.
        if (flow.getBalance(currentStreamId) == 0 && flow.getRemainingAmount(currentStreamId) == 0) {
            return;
        }

        // Bound the time so that it is between last time update and current time.
        time = uint40(_bound(time, flow.getLastTimeUpdate(currentStreamId), block.timestamp));

        // There is an edge case when the sender is the same as the recipient. In this scenario, the withdrawal
        // address must be set to the recipient.
        address sender = flowStore.senders(currentStreamId);
        if (sender == currentRecipient && to != currentRecipient) {
            to = currentRecipient;
        }

        uint128 withdrawAmount = flow.withdrawableAmountOf(currentStreamId, time);

        // Withdraw from the stream.
        flow.withdrawAt({ streamId: currentStreamId, to: to, time: time });

        // Store the extracted amount.
        flowStore.updateStreamExtractedAmountsSum(currentStreamId, withdrawAmount);
    }
}
