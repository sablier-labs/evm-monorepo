// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

/// @title Errors
/// @notice Library with custom erros used across the Flow contract.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when an unexpected error occurs during a batch call.
    error BatchError(bytes errorData);

    /// @notice Thrown when `msg.sender` is not the admin.
    error CallerNotAdmin(address admin, address caller);

    /// @notice Thrown when trying to delegate call to a function that disallows delegate calls.
    error DelegateCall();

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-FLOW-STATE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to transfer Stream NFT when transferability is disabled.
    error SablierFlowState_NotTransferable(uint256 streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                    SABLIER-FLOW
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a stream with a broker fee more than the allowed.
    error SablierFlow_BrokerFeeTooHigh(UD60x18 brokerFee, UD60x18 maxBrokerFee);

    /// @notice Thrown when trying to create a stream with a broker recipient address as zero.
    error SablierFlow_BrokerAddressZero();

    /// @notice Thrown when voiding a stream with zero debt.
    error SablierFlow_DebtZero(uint256 streamId);

    /// @notice Thrown when trying to create a stream with an asset with no decimals.
    error SablierFlow_InvalidAssetDecimals(address asset);

    /// @notice Thrown when an unexpected error occurs during the calculation of an amount.
    error SablierFlow_InvalidCalculation(uint256 streamId, uint128 availableAmount, uint128 amount);

    /// @notice Thrown when trying to withdraw assets with a withdrawal time not greater than or equal to
    /// `lastTimeUpdate`.
    error SablierFlow_LastUpdateNotLessThanWithdrawalTime(uint40 lastUpdate, uint40 time);

    /// @notice Thrown when the ID references a null stream.
    error SablierFlow_Null(uint256 streamId);

    /// @notice Thrown when trying to refund an amount greater than the refundable amount.
    error SablierFlow_Overrefund(uint256 streamId, uint128 refundAmount, uint128 refundableAmount);

    /// @notice Thrown when trying to change the rate per second with the same rate per second.
    error SablierFlow_RatePerSecondNotDifferent(uint128 ratePerSecond);

    /// @notice Thrown when trying to set the rate per second of a stream to zero.
    error SablierFlow_RatePerSecondZero();

    /// @notice Thrown when trying to refund zero assets from a stream.
    error SablierFlow_RefundAmountZero();

    /// @notice Thrown when trying to create a stream with the sender as the zero address.
    error SablierFlow_SenderZeroAddress();

    /// @notice Thrown when trying to perform an action with a paused stream.
    error SablierFlow_StreamPaused(uint256 streamId);

    /// @notice Thrown when trying to restart a stream that is not paused.
    error SablierFlow_StreamNotPaused(uint256 streamId);

    /// @notice Thrown when trying to create a stream with a zero transfer amount.
    error SablierFlow_TransferAmountZero();

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierFlow_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to withdraw to an address other than the recipient's.
    error SablierFlow_WithdrawalAddressNotRecipient(uint256 streamId, address caller, address to);

    /// @notice Thrown when trying to withdraw but the stream no funds available.
    error SablierFlow_WithdrawNoFundsAvailable(uint256 streamId);

    /// @notice Thrown when trying to withdraw assets with a withdrawal time in the future.
    error SablierFlow_WithdrawalTimeInTheFuture(uint40 time, uint256 currentTime);

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierFlow_WithdrawToZeroAddress();
}
