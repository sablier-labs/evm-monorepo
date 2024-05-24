// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

/// @title Errors
/// @notice Library with custom erros used across the OpenEnded contract.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to delegate call to a function that disallows delegate calls.
    error DelegateCall();

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-OpenEnded
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a stream with a broker fee more than the allowed.
    error SablierV2OpenEnded_BrokerFeeTooHigh(uint256 streamId, UD60x18 fee, UD60x18 maxFee);

    /// @notice Thrown when trying to create a stream with a broker recipient address as zero.
    error SablierV2OpenEnded_BrokerAddressZero();

    /// @notice Thrown when trying to create a stream with a zero deposit amount.
    error SablierV2OpenEnded_DepositAmountZero();

    /// @notice Thrown when trying to create a stream with an asset with no decimals.
    error SablierV2OpenEnded_InvalidAssetDecimals(IERC20 asset);

    /// @notice Thrown when an unexpected error occurs during the calculation of an amount.
    error SablierV2OpenEnded_InvalidCalculation(uint256 streamId, uint128 availableAmount, uint128 amount);

    /// @notice Thrown when trying to withdraw assets with a withdrawal time not greater than or equal to
    /// `lastTimeUpdate`.
    error SablierV2OpenEnded_LastUpdateNotLessThanWithdrawalTime(uint40 lastUpdate, uint40 time);

    /// @notice Thrown when trying to transfer Stream NFT when transferability is disabled.
    error SablierV2OpenEndedState_NotTransferable(uint256 streamId);

    /// @notice Thrown when the ID references a null stream.
    error SablierV2OpenEnded_Null(uint256 streamId);

    /// @notice Thrown when trying to refund an amount greater than the refundable amount.
    error SablierV2OpenEnded_Overrefund(uint256 streamId, uint128 refundAmount, uint128 refundableAmount);

    /// @notice Thrown when trying to change the rate per second with the same rate per second.
    error SablierV2OpenEnded_RatePerSecondNotDifferent(uint128 ratePerSecond);

    /// @notice Thrown when trying to set the rate per second of a stream to zero.
    error SablierV2OpenEnded_RatePerSecondZero();

    /// @notice Thrown when trying to refund zero assets from a stream.
    error SablierV2OpenEnded_RefundAmountZero();

    /// @notice Thrown when trying to create a stream with the sender as the zero address.
    error SablierV2OpenEnded_SenderZeroAddress();

    /// @notice Thrown when trying to perform an action with a paused stream.
    error SablierV2OpenEnded_StreamPaused(uint256 streamId);

    /// @notice Thrown when trying to restart a stream that is not paused.
    error SablierV2OpenEnded_StreamNotPaused(uint256 streamId);

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierV2OpenEnded_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to withdraw to an address other than the recipient's.
    error SablierV2OpenEnded_WithdrawalAddressNotRecipient(uint256 streamId, address caller, address to);

    /// @notice Thrown when trying to withdraw but the stream no funds available.
    error SablierV2OpenEnded_WithdrawNoFundsAvailable(uint256 streamId);

    /// @notice Thrown when trying to withdraw assets with a withdrawal time in the future.
    error SablierV2OpenEnded_WithdrawalTimeInTheFuture(uint40 time, uint256 currentTime);

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierV2OpenEnded_WithdrawToZeroAddress();
}
