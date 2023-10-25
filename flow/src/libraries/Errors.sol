// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.20;

/// @title Errors
/// @notice Library with custom erros used across the payroll contract.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-PAYROLL
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to set the amount per second of a stream to zero.
    error SablierV2Payroll_AmountPerSecondZero();

    /// @notice Thrown when trying to create a payroll stream with a zero deposit amount.
    error SablierV2Payroll_DepositAmountZero();

    /// @notice Thrown when trying to deposit on multiple streams and the number of stream ids does
    /// not match the number of deposit amounts.
    error SablierV2Payroll_DepositArrayCountsNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Thrown when the id references a null stream.
    error SablierV2Payroll_Null(uint256 streamId);

    /// @notice Thrown when trying to refund or withdraw with an amount greater than the available amount.
    error SablierV2Payroll_Overdraw(uint256 streamId, uint128 amount, uint128 availableAmount);

    /// @notice Thrown when trying to create a payroll stream with the recipient as the zero address.
    error SablierV2Payroll_RecipientZeroAddress();

    /// @notice Thrown when trying to create a payroll stream with the sender as the zero address.
    error SablierV2Payroll_SenderZeroAddress();

    /// @notice Thrown when trying to cancel or deposit a canceled stream.
    error SablierV2Payroll_StreamCanceled(uint256 streamId);

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierV2Payroll_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to refund or withdraw zero assets from a stream.
    error SablierV2Payroll_AmountZero(uint256 streamId);

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierV2Payroll_WithdrawToZeroAddress();
}
