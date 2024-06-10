// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { FlowStore } from "../stores/FlowStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

contract FlowHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal currentRecipient;
    address internal currentSender;
    uint256 internal currentStreamId;

    /// @dev Debt, remaining and recent amount mapped to each stream id.
    mapping(uint256 streamId => uint128 amount) public previousDebtOf;
    mapping(uint256 streamId => uint128 amount) public lastRecentAmountOf;
    mapping(uint256 streamId => uint128 amount) public lastRemainingAmountOf;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(FlowStore flowStore_, ISablierFlow flow_) BaseHandler(flowStore_, flow_) { }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Updates the states of Flow stream.
    modifier updateFlowStates() {
        previousDebtOf[currentStreamId] = flow.streamDebtOf(currentStreamId);
        lastRemainingAmountOf[currentStreamId] = flow.getRemainingAmount(currentStreamId);
        lastRecentAmountOf[currentStreamId] = flow.recentAmountOf(currentStreamId);
        _;
    }

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
        currentRecipient = flowStore.recipients(currentStreamId);
        resetPrank(currentRecipient);
        _;
    }

    modifier useFuzzedStreamSender() {
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
        updateFlowStates
    {
        // Only non paused streams can have their rate per second adjusted.
        vm.assume(!flow.isPaused(currentStreamId));

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
        updateFlowStates
    {
        // Paused streams cannot be paused again.
        vm.assume(!flow.isPaused(currentStreamId));

        // Pause the stream.
        flow.pause(currentStreamId);
    }

    function deposit(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 transferAmount
    )
        external
        instrument("deposit")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
        updateFlowStates
    {
        // Calculate the upper bound, based on the asset decimals, for the transfer amount.
        uint128 upperBound = getTransferAmount(1_000_000e18, flow.getAssetDecimals(currentStreamId));

        // Bound the transfer amount.
        transferAmount = uint128(_bound(transferAmount, 100, upperBound));

        IERC20 asset = flow.getAsset(currentStreamId);

        // Mint enough assets to the Sender.
        deal({ token: address(asset), to: currentSender, give: asset.balanceOf(currentSender) + transferAmount });

        // Approve {SablierFlow} to spend the assets.
        asset.approve({ spender: address(flow), value: transferAmount });

        // Deposit into the stream.
        flow.deposit({ streamId: currentStreamId, transferAmount: transferAmount });

        uint128 normalizedAmount = getNormalizedAmount(transferAmount, flow.getAssetDecimals(currentStreamId));

        // Update the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(currentStreamId, normalizedAmount);
    }

    function refund(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 refundAmount
    )
        external
        instrument("refund")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
        updateFlowStates
    {
        uint128 refundableAmount = flow.refundableAmountOf(currentStreamId);

        // The protocol doesn't allow zero refund amount.
        vm.assume(refundableAmount > 0);

        // Bound the refund amount so that it does not exceed the `refundableAmount`.
        refundAmount = uint128(_bound(refundAmount, 1, refundableAmount));

        // Refund from stream.
        flow.refund(currentStreamId, refundAmount);

        // Update the refunded amount.
        flowStore.updateStreamRefundedAmountsSum(currentStreamId, refundAmount);
    }

    function restart(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 ratePerSecond
    )
        external
        instrument("restart")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
        updateFlowStates
    {
        // Only paused streams can be restarted.
        vm.assume(flow.isPaused(currentStreamId));

        // Bound the stream parameter.
        ratePerSecond = uint128(_bound(ratePerSecond, 0.0001e18, 1e18));

        // Restart the stream.
        flow.restart(currentStreamId, ratePerSecond);
    }

    function void(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed
    )
        external
        instrument("void")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
        updateFlowStates
    {
        // Check if the debt is not zero.
        vm.assume(flow.streamDebtOf(currentStreamId) > 0);

        // Void the stream.
        flow.void(currentStreamId);
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
        updateFlowStates
    {
        // The protocol doesn't allow the withdrawal address to be the zero address.
        vm.assume(to != address(0));

        // Check if there is anything to withdraw.
        vm.assume(flow.withdrawableAmountOf(currentStreamId) > 0);

        // Bound the time so that it is between last time update and current time.
        time = uint40(_bound(time, flow.getLastTimeUpdate(currentStreamId), getBlockTimestamp()));

        // There is an edge case when the sender is the same as the recipient. In this scenario, the withdrawal
        // address must be set to the recipient.
        address sender = flowStore.senders(currentStreamId);
        if (sender == currentRecipient && to != currentRecipient) {
            to = currentRecipient;
        }

        uint128 initialBalance = flow.getBalance(currentStreamId);

        // Withdraw from the stream.
        flow.withdrawAt({ streamId: currentStreamId, to: to, time: time });

        uint128 amountWithdrawn = initialBalance - flow.getBalance(currentStreamId);

        // Update the withdrawn amount.
        flowStore.updateStreamWithdrawnAmountsSum(currentStreamId, amountWithdrawn);
    }
}
