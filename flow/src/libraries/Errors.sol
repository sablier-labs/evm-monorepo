// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD21x18 } from "@prb/math/src/UD21x18.sol";

/// @title Errors
/// @notice Library with custom errors used across the Flow contract.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    SABLIER-FLOW
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a stream with a zero deposit amount.
    error SablierFlow_DepositAmountZero(uint256 streamId);

    /// @notice Thrown when an unexpected error occurs during the calculation of an amount.
    error SablierFlow_InvalidCalculation(uint256 streamId, uint128 availableAmount, uint128 amount);

    /// @notice Thrown when trying to create a stream with an token with no decimals.
    error SablierFlow_InvalidTokenDecimals(address token);

    /// @notice Thrown when trying to adjust the rate per second to zero.
    error SablierFlow_NewRatePerSecondZero(uint256 streamId);

    /// @notice Thrown when the recipient address does not match the stream's recipient.
    error SablierFlow_NotStreamRecipient(address recipient, address streamRecipient);

    /// @notice Thrown when the sender address does not match the stream's sender.
    error SablierFlow_NotStreamSender(address sender, address streamSender);

    /// @notice Thrown when the ID references a null stream.
    error SablierFlow_Null(uint256 streamId);

    /// @notice Thrown when trying to withdraw an amount greater than the withdrawable amount.
    error SablierFlow_Overdraw(uint256 streamId, uint128 amount, uint128 withdrawableAmount);

    /// @notice Thrown when trying to change the rate per second with the same rate per second.
    error SablierFlow_RatePerSecondNotDifferent(uint256 streamId, UD21x18 ratePerSecond);

    /// @notice Thrown when trying to create a pending stream with rate per second zero.
    error SablierFlow_RatePerSecondZero();

    /// @notice Thrown when trying to refund zero tokens from a stream.
    error SablierFlow_RefundAmountZero(uint256 streamId);

    /// @notice Thrown when trying to refund an amount greater than the refundable amount.
    error SablierFlow_RefundOverflow(uint256 streamId, uint128 refundAmount, uint128 refundableAmount);

    /// @notice Thrown when trying to create a stream with the sender as the zero address.
    error SablierFlow_SenderZeroAddress();

    /// @notice Thrown when trying to get depletion time of a stream with zero balance.
    error SablierFlow_StreamBalanceZero(uint256 streamId);

    /// @notice Thrown when trying to perform an action with a paused stream.
    error SablierFlow_StreamPaused(uint256 streamId);

    /// @notice Thrown when trying to restart a stream that is not paused.
    error SablierFlow_StreamNotPaused(uint256 streamId);

    /// @notice Thrown when trying to pause a stream that has not started.
    error SablierFlow_StreamNotStarted(uint256 streamId, uint40 snapshotTime);

    /// @notice Thrown when trying to perform an action with a voided stream.
    error SablierFlow_StreamVoided(uint256 streamId);

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierFlow_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to withdraw to an address other than the recipient's.
    error SablierFlow_WithdrawalAddressNotRecipient(uint256 streamId, address caller, address to);

    /// @notice Thrown when trying to withdraw zero tokens from a stream.
    error SablierFlow_WithdrawAmountZero(uint256 streamId);

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierFlow_WithdrawToZeroAddress(uint256 streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-FLOW-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the fee transfer fails.
    error SablierFlowBase_FeeTransferFail(address admin, uint256 feeAmount);

    /// @notice Thrown when trying to transfer Stream NFT when transferability is disabled.
    error SablierFlowBase_NotTransferable(uint256 streamId);

    /// @notice Thrown when trying to recover for a token with zero surplus.
    error SablierFlowBase_SurplusZero(address token);
}
