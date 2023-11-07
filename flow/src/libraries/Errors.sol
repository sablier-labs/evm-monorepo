// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    /// @notice Thrown when trying to set the amount per second of a stream to zero.
    error SablierV2OpenEnded_ratePerSecondZero();

    /// @notice Thrown when trying to change the amount per second with the same amount per second.
    error SablierV2OpenEnded_ratePerSecondNotDifferent(uint128 ratePerSecond);

    /// @notice Thrown when trying to create a OpenEnded stream with a zero deposit amount.
    error SablierV2OpenEnded_DepositAmountZero();

    /// @notice Thrown when trying to deposit on multiple streams and the number of stream ids does
    /// not match the number of deposit amounts.
    error SablierV2OpenEnded_DepositArrayCountsNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Thrown when trying to create a stream with an asset with no decimals.
    error SablierV2OpenEnded_InvalidAssetDecimals(IERC20 asset);

    /// @notice Thrown when an unexpected error occurs during the calculation of an amount.
    error SablierV2OpenEnded_InvalidCalculation(uint256 streamId, uint128 balance, uint128 amount);

    /// @notice Thrown when the id references a null stream.
    error SablierV2OpenEnded_Null(uint256 streamId);

    /// @notice Thrown when trying to withdraw an amount greater than the withdrawable amount.
    error SablierV2OpenEnded_Overdraw(uint256 streamId, uint128 amount, uint128 withdrawableAmount);

    /// @notice Thrown when trying to refund an amount greater than the refundable amount.
    error SablierV2OpenEnded_Overrefund(uint256 streamId, uint128 amount, uint128 refundableAmount);

    /// @notice Thrown when trying to create a OpenEnded stream with the recipient as the zero address.
    error SablierV2OpenEnded_RecipientZeroAddress();

    /// @notice Thrown when trying to refund zero assets from a stream.
    error SablierV2OpenEnded_RefundAmountZero();

    /// @notice Thrown when trying to create a OpenEnded stream with the sender as the zero address.
    error SablierV2OpenEnded_SenderZeroAddress();

    /// @notice Thrown when trying to perform an action with a canceled stream.
    error SablierV2OpenEnded_StreamCanceled(uint256 streamId);

    /// @notice Thrown when trying to restart a stream that is not canceled.
    error SablierV2OpenEnded_StreamNotCanceled(uint256 streamId);

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierV2OpenEnded_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to withdraw zero assets from a stream.
    error SablierV2OpenEnded_WithdrawAmountZero();

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierV2OpenEnded_WithdrawToZeroAddress();
}
