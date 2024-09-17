// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

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

    /// @dev Snapshot times mapped by stream IDs.
    mapping(uint256 streamId => uint40 snapshotTime) public previousSnapshotTime;

    /// @dev Total debts mapped by stream IDs.
    mapping(uint256 streamId => uint128 amount) public previousTotalDebtOf;

    /// @dev Uncovered debts mapped by stream IDs.
    mapping(uint256 streamId => uint128 amount) public previousUncoveredDebtOf;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(FlowStore flowStore_, ISablierFlow flow_) BaseHandler(flowStore_, flow_) { }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Updates the states of handler right before calling each Flow function.
    modifier updateFlowHandlerStates() {
        previousSnapshotTime[currentStreamId] = flow.getSnapshotTime(currentStreamId);
        previousTotalDebtOf[currentStreamId] = flow.totalDebtOf(currentStreamId);
        previousUncoveredDebtOf[currentStreamId] = flow.uncoveredDebtOf(currentStreamId);
        _;
    }

    /// @dev Picks a random stream from the store.
    /// @param streamIndex A fuzzed value to pick a stream from flowStore.
    modifier useFuzzedStream(uint256 streamIndex) {
        uint256 lastStreamId = flowStore.lastStreamId();
        if (lastStreamId == 0) {
            return;
        }
        vm.assume(streamIndex < lastStreamId);
        currentStreamId = flowStore.streamIds(streamIndex);
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
        uint256 timeJump,
        uint256 streamIndex,
        UD21x18 newRatePerSecond
    )
        external
        instrument("adjustRatePerSecond")
        useFuzzedStream(streamIndex)
        useFuzzedStreamSender
        adjustTimestamp(timeJump)
        updateFlowHandlerStates
    {
        // Only non paused streams can have their rate per second adjusted.
        vm.assume(!flow.isPaused(currentStreamId));

        // Use a realistic range for the rate per second.
        vm.assume(newRatePerSecond.unwrap() >= 0.0000000001e18 && newRatePerSecond.unwrap() <= 10e18);

        // The rate per second must be different from the current rate per second.
        vm.assume(newRatePerSecond.unwrap() != flow.getRatePerSecond(currentStreamId).unwrap());

        // Adjust the rate per second.
        flow.adjustRatePerSecond(currentStreamId, newRatePerSecond);
    }

    function deposit(
        uint256 timeJump,
        uint256 streamIndex,
        uint128 depositAmount
    )
        external
        instrument("deposit")
        useFuzzedStream(streamIndex)
        useFuzzedStreamSender
        adjustTimestamp(timeJump)
        updateFlowHandlerStates
    {
        // Voided streams cannot be deposited on.
        vm.assume(!flow.isVoided(currentStreamId));

        // Calculate the upper bound, based on the token decimals, for the deposit amount.
        uint128 upperBound = getDenormalizedAmount(1_000_000e18, flow.getTokenDecimals(currentStreamId));

        // Make sure the deposit amount is non-zero and less than values that could cause an overflow.
        vm.assume(depositAmount >= 100 && depositAmount <= upperBound);

        IERC20 token = flow.getToken(currentStreamId);

        // Mint enough tokens to the Sender.
        deal({ token: address(token), to: currentSender, give: token.balanceOf(currentSender) + depositAmount });

        // Approve {SablierFlow} to spend the tokens.
        token.approve({ spender: address(flow), value: depositAmount });

        // Deposit into the stream.
        flow.deposit({ streamId: currentStreamId, amount: depositAmount });

        // Update the deposited amount.
        flowStore.updateStreamDepositedAmountsSum(currentStreamId, depositAmount);
    }

    /// @dev A function that does nothing but warp the time into the future.
    function passTime(uint256 timeJump) external instrument("passTime") adjustTimestamp(timeJump) { }

    function pause(
        uint256 timeJump,
        uint256 streamIndex
    )
        external
        instrument("pause")
        useFuzzedStream(streamIndex)
        useFuzzedStreamSender
        adjustTimestamp(timeJump)
        updateFlowHandlerStates
    {
        // Paused streams cannot be paused again.
        vm.assume(!flow.isPaused(currentStreamId));

        // Pause the stream.
        flow.pause(currentStreamId);
    }

    function refund(
        uint256 timeJump,
        uint256 streamIndex,
        uint128 refundAmount
    )
        external
        instrument("refund")
        useFuzzedStream(streamIndex)
        useFuzzedStreamSender
        adjustTimestamp(timeJump)
        updateFlowHandlerStates
    {
        // Voided streams cannot be refunded.
        vm.assume(!flow.isVoided(currentStreamId));

        uint128 refundableAmount = flow.refundableAmountOf(currentStreamId);

        // The protocol doesn't allow zero refund amounts.
        vm.assume(refundableAmount > 0);

        // Make sure the refund amount is non-zero and it is less or equal to the maximum refundable amount.
        vm.assume(refundAmount >= 1 && refundAmount <= refundableAmount);

        // Refund from stream.
        flow.refund(currentStreamId, refundAmount);

        // Update the refunded amount.
        flowStore.updateStreamRefundedAmountsSum(currentStreamId, refundAmount);
    }

    function restart(
        uint256 timeJump,
        uint256 streamIndex,
        UD21x18 ratePerSecond
    )
        external
        instrument("restart")
        useFuzzedStream(streamIndex)
        useFuzzedStreamSender
        adjustTimestamp(timeJump)
        updateFlowHandlerStates
    {
        // Voided streams cannot be restarted.
        vm.assume(!flow.isVoided(currentStreamId));

        // Only paused streams can be restarted.
        vm.assume(flow.isPaused(currentStreamId));

        // Use a realistic range for the rate per second.
        vm.assume(ratePerSecond.unwrap() >= 0.0000000001e18 && ratePerSecond.unwrap() <= 10e18);

        // Restart the stream.
        flow.restart(currentStreamId, ratePerSecond);
    }

    function void(
        uint256 timeJump,
        uint256 streamIndex
    )
        external
        instrument("void")
        useFuzzedStream(streamIndex)
        useFuzzedStreamRecipient
        adjustTimestamp(timeJump)
        updateFlowHandlerStates
    {
        // Voided streams cannot be voided again.
        vm.assume(!flow.isVoided(currentStreamId));

        // Check if the uncovered debt is greater than zero.
        vm.assume(flow.uncoveredDebtOf(currentStreamId) > 0);

        // Void the stream.
        flow.void(currentStreamId);
    }

    function withdraw(
        uint256 timeJump,
        uint256 streamIndex,
        address to,
        uint128 amount
    )
        external
        instrument("withdraw")
        useFuzzedStream(streamIndex)
        useFuzzedStreamRecipient
        adjustTimestamp(timeJump)
        updateFlowHandlerStates
    {
        // The protocol doesn't allow the withdrawal address to be the zero address.
        vm.assume(to != address(0));

        // Check if there is anything to withdraw.
        vm.assume(flow.coveredDebtOf(currentStreamId) > 0);

        // Make sure the withdraw amount is non-zero and it is less or equal to the maximum wihtdrawable amount.
        vm.assume(amount >= 1 && amount <= flow.withdrawableAmountOf(currentStreamId));

        // There is an edge case when the sender is the same as the recipient. In this scenario, the withdrawal
        // address must be set to the recipient.
        address sender = flowStore.senders(currentStreamId);
        if (sender == currentRecipient && to != currentRecipient) {
            to = currentRecipient;
        }

        // Withdraw from the stream.
        flow.withdraw({ streamId: currentStreamId, to: to, amount: amount });

        // Update the withdrawn amount.
        flowStore.updateStreamWithdrawnAmountsSum(currentStreamId, amount);
    }
}
