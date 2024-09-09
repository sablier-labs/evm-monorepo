// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";
import { ud, UD60x18, UNIT, ZERO } from "@prb/math/src/UD60x18.sol";

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
        UD21x18 newRatePerSecond
    )
        external
        instrument("adjustRatePerSecond")
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
        adjustTimestamp(timeJumpSeed)
        updateFlowHandlerStates
    {
        // Only non paused streams can have their rate per second adjusted.
        vm.assume(!flow.isPaused(currentStreamId));

        // Bound the rate per second.
        newRatePerSecond = boundRatePerSecond(newRatePerSecond);

        // The rate per second must be different from the current rate per second.
        if (newRatePerSecond.unwrap() == flow.getRatePerSecond(currentStreamId).unwrap()) {
            newRatePerSecond = ud21x18(newRatePerSecond.unwrap() + 1);
        }

        // Adjust the rate per second.
        flow.adjustRatePerSecond(currentStreamId, newRatePerSecond);
    }

    function deposit(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 depositAmount
    )
        external
        instrument("deposit")
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
        adjustTimestamp(timeJumpSeed)
        updateFlowHandlerStates
    {
        // Voided streams cannot be deposited on.
        vm.assume(!flow.isVoided(currentStreamId));

        // Calculate the upper bound, based on the token decimals, for the deposit amount.
        uint128 upperBound = getDenormalizedAmount(1_000_000e18, flow.getTokenDecimals(currentStreamId));

        // Bound the deposit amount.
        depositAmount = boundUint128(depositAmount, 100, upperBound);

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
    function passTime(uint256 timeJumpSeed) external instrument("passTime") adjustTimestamp(timeJumpSeed) { }

    function pause(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed
    )
        external
        instrument("pause")
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
        adjustTimestamp(timeJumpSeed)
        updateFlowHandlerStates
    {
        // Paused streams cannot be paused again.
        vm.assume(!flow.isPaused(currentStreamId));

        // Pause the stream.
        flow.pause(currentStreamId);
    }

    function refund(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        uint128 refundAmount
    )
        external
        instrument("refund")
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
        adjustTimestamp(timeJumpSeed)
        updateFlowHandlerStates
    {
        // Voided streams cannot be refunded.
        vm.assume(!flow.isVoided(currentStreamId));

        uint128 refundableAmount = flow.refundableAmountOf(currentStreamId);

        // The protocol doesn't allow zero refund amounts.
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
        UD21x18 ratePerSecond
    )
        external
        instrument("restart")
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
        adjustTimestamp(timeJumpSeed)
        updateFlowHandlerStates
    {
        // Voided streams cannot be restarted.
        vm.assume(!flow.isVoided(currentStreamId));

        // Only paused streams can be restarted.
        vm.assume(flow.isPaused(currentStreamId));

        // Bound the stream parameter.
        ratePerSecond = boundRatePerSecond(ratePerSecond);

        // Restart the stream.
        flow.restart(currentStreamId, ratePerSecond);
    }

    function void(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed
    )
        external
        instrument("void")
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
        adjustTimestamp(timeJumpSeed)
        updateFlowHandlerStates
    {
        // Voided streams cannot be voided again.
        vm.assume(!flow.isVoided(currentStreamId));

        // Check if the uncovered debt is greater than zero.
        vm.assume(flow.uncoveredDebtOf(currentStreamId) > 0);

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
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
        adjustTimestamp(timeJumpSeed)
        updateFlowHandlerStates
    {
        // The protocol doesn't allow the withdrawal address to be the zero address.
        vm.assume(to != address(0));

        // Check if there is anything to withdraw.
        vm.assume(flow.coveredDebtOf(currentStreamId) > 0);

        // Bound the time so that it is between snapshot time and current time.
        time = uint40(_bound(time, flow.getSnapshotTime(currentStreamId), getBlockTimestamp()));

        // There is an edge case when the sender is the same as the recipient. In this scenario, the withdrawal
        // address must be set to the recipient.
        address sender = flowStore.senders(currentStreamId);
        if (sender == currentRecipient && to != currentRecipient) {
            to = currentRecipient;
        }

        uint128 initialBalance = flow.getBalance(currentStreamId);

        // We need to calculate the total debt at the time of withdrawal. Otherwise the modifier updates the mappings
        // with `block.timestamp` as the time reference.
        uint128 totalDebt = flow.getSnapshotDebt(currentStreamId)
            + getDenormalizedAmount({
                amount: flow.getRatePerSecond(currentStreamId).unwrap() * (time - flow.getSnapshotTime(currentStreamId)),
                decimals: flow.getTokenDecimals(currentStreamId)
            });
        uint128 uncoveredDebt = initialBalance < totalDebt ? totalDebt - initialBalance : 0;
        previousTotalDebtOf[currentStreamId] = totalDebt;
        previousUncoveredDebtOf[currentStreamId] = uncoveredDebt;

        // Withdraw from the stream.
        flow.withdrawAt({ streamId: currentStreamId, to: to, time: time });

        uint128 amountWithdrawn = initialBalance - flow.getBalance(currentStreamId);

        UD60x18 protocolFee = flow.protocolFee(flow.getToken(currentStreamId));
        if (protocolFee > ZERO) {
            amountWithdrawn -= uint128((ud(amountWithdrawn).mul(UNIT - protocolFee)).unwrap());
        }

        // Update the withdrawn amount.
        flowStore.updateStreamWithdrawnAmountsSum(currentStreamId, amountWithdrawn);
    }
}
