// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Lockup } from "../types/Lockup.sol";

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER-BATCH-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    error SablierBatchLockup_BatchSizeZero();

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a linear stream with a cliff time not strictly less than the end time.
    error SablierLockupHelpers_CliffTimeNotLessThanEndTime(uint40 cliffTime, uint40 endTime);

    /// @notice Thrown when trying to create a stream with a non zero cliff unlock amount when the cliff time is zero.
    error SablierLockupHelpers_CliffTimeZeroUnlockAmountNotZero(uint128 cliffUnlockAmount);

    /// @notice Thrown when trying to create a stream with the native token.
    error SablierLockupHelpers_CreateNativeToken(address nativeToken);

    /// @notice Thrown when trying to create a dynamic stream with a deposit amount not equal to the sum of the segment
    /// amounts.
    error SablierLockupHelpers_DepositAmountNotEqualToSegmentAmountsSum(
        uint128 depositAmount,
        uint128 segmentAmountsSum
    );

    /// @notice Thrown when trying to create a tranched stream with a deposit amount not equal to the sum of the tranche
    /// amounts.
    error SablierLockupHelpers_DepositAmountNotEqualToTrancheAmountsSum(
        uint128 depositAmount,
        uint128 trancheAmountsSum
    );

    /// @notice Thrown when trying to create a stream with a zero deposit amount.
    error SablierLockupHelpers_DepositAmountZero();

    /// @notice Thrown when trying to create a dynamic stream with end time not equal to the last segment's timestamp.
    error SablierLockupHelpers_EndTimeNotEqualToLastSegmentTimestamp(uint40 endTime, uint40 lastSegmentTimestamp);

    /// @notice Thrown when trying to create a tranched stream with end time not equal to the last tranche's timestamp.
    error SablierLockupHelpers_EndTimeNotEqualToLastTrancheTimestamp(uint40 endTime, uint40 lastTrancheTimestamp);

    /// @notice Thrown when trying to create a linear stream with granularity greater than the streamable range.
    error SablierLockupHelpers_GranularityTooHigh(uint40 granularity, uint40 streamableRange);

    /// @notice Thrown when trying to create a dynamic stream with no segments.
    error SablierLockupHelpers_SegmentCountZero();

    /// @notice Thrown when trying to create a dynamic stream with unordered segment timestamps.
    error SablierLockupHelpers_SegmentTimestampsNotOrdered(
        uint256 index,
        uint40 previousTimestamp,
        uint40 currentTimestamp
    );

    /// @notice Thrown when trying to create a stream with the sender as the zero address.
    error SablierLockupHelpers_SenderZeroAddress();

    /// @notice Thrown when trying to create a stream with a shape string exceeding 32 bytes.
    error SablierLockupHelpers_ShapeExceeds32Bytes(uint256 shapeLength);

    /// @notice Thrown when trying to create a linear stream with a start time not strictly less than the cliff time,
    /// when the cliff time does not have a zero value.
    error SablierLockupHelpers_StartTimeNotLessThanCliffTime(uint40 startTime, uint40 cliffTime);

    /// @notice Thrown when trying to create a linear stream with a start time not strictly less than the end time.
    error SablierLockupHelpers_StartTimeNotLessThanEndTime(uint40 startTime, uint40 endTime);

    /// @notice Thrown when trying to create a dynamic stream with a start time not strictly less than the first
    /// segment timestamp.
    error SablierLockupHelpers_StartTimeNotLessThanFirstSegmentTimestamp(
        uint40 startTime,
        uint40 firstSegmentTimestamp
    );

    /// @notice Thrown when trying to create a tranched stream with a start time not strictly less than the first
    /// tranche timestamp.
    error SablierLockupHelpers_StartTimeNotLessThanFirstTrancheTimestamp(
        uint40 startTime,
        uint40 firstTrancheTimestamp
    );

    /// @notice Thrown when trying to create a stream with a zero start time.
    error SablierLockupHelpers_StartTimeZero();

    /// @notice Thrown when trying to create a tranched stream with no tranches.
    error SablierLockupHelpers_TrancheCountZero();

    /// @notice Thrown when trying to create a tranched stream with unordered tranche timestamps.
    error SablierLockupHelpers_TrancheTimestampsNotOrdered(
        uint256 index,
        uint40 previousTimestamp,
        uint40 currentTimestamp
    );

    /// @notice Thrown when trying to create a stream with the sum of the unlock amounts greater than the deposit
    /// amount.
    error SablierLockupHelpers_UnlockAmountsSumTooHigh(
        uint128 depositAmount,
        uint128 startUnlockAmount,
        uint128 cliffUnlockAmount
    );

    /*//////////////////////////////////////////////////////////////////////////
                                    SABLIER-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to allow to hook a contract that doesn't implement the interface correctly.
    error SablierLockup_AllowToHookUnsupportedInterface(address recipient);

    /// @notice Thrown when trying to allow to hook an address with no code.
    error SablierLockup_AllowToHookZeroCodeSize(address recipient);

    /// @notice Thrown when the fee transfer fails.
    error SablierLockup_FeeTransferFailed(address comptroller, uint256 feeAmount);

    /// @notice Thrown when trying to withdraw with a fee amount less than the minimum fee.
    error SablierLockup_InsufficientFeePayment(uint256 feePaid, uint256 minFeeWei);

    /// @notice Thrown when the hook does not return the correct selector.
    error SablierLockup_InvalidHookSelector(address recipient);

    /// @notice Thrown when trying to set the native token address when it is already set.
    error SablierLockup_NativeTokenAlreadySet(address nativeToken);

    /// @notice Thrown when trying to transfer Stream NFT when transferability is disabled.
    error SablierLockup_NotTransferable(uint256 tokenId);

    /// @notice Thrown when trying to withdraw an amount greater than the withdrawable amount.
    error SablierLockup_Overdraw(uint256 streamId, uint128 amount, uint128 withdrawableAmount);

    /// @notice Thrown when trying to withdraw a partial amount from a LPG stream.
    error SablierLockup_WithdrawAmountNotEqualWithdrawableAmount(
        uint256 streamId,
        uint128 amount,
        uint128 withdrawableAmount
    );

    /// @notice Thrown when trying to cancel or renounce a canceled stream.
    error SablierLockup_StreamCanceled(uint256 streamId);

    /// @notice Thrown when trying to cancel, renounce, or withdraw from a depleted stream.
    error SablierLockup_StreamDepleted(uint256 streamId);

    /// @notice Thrown when trying to cancel or renounce a stream that is not cancelable.
    error SablierLockup_StreamNotCancelable(uint256 streamId);

    /// @notice Thrown when trying to burn a stream that is not depleted.
    error SablierLockup_StreamNotDepleted(uint256 streamId);

    /// @notice Thrown when trying to cancel or renounce a settled stream.
    error SablierLockup_StreamSettled(uint256 streamId);

    /// @notice Thrown when trying to create a price-gated stream with a target price not greater than the current
    /// oracle price.
    error SablierLockup_TargetPriceTooLow(uint128 targetPrice, uint128 latestPrice);

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierLockup_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to withdraw to an address other than the recipient's.
    error SablierLockup_WithdrawalAddressNotRecipient(uint256 streamId, address caller, address to);

    /// @notice Thrown when trying to withdraw zero tokens from a stream.
    error SablierLockup_WithdrawAmountZero(uint256 streamId);

    /// @notice Thrown when trying to withdraw from multiple streams and the number of stream IDs does
    /// not match the number of withdraw amounts.
    error SablierLockup_WithdrawArrayCountsNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierLockup_WithdrawToZeroAddress(uint256 streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER-LOCKUP-STATE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a function is called on a stream that does not use the expected Lockup model.
    error SablierLockupState_NotExpectedModel(Lockup.Model actualLockupModel, Lockup.Model expectedLockupModel);

    /// @notice Thrown when the ID references a null stream.
    error SablierLockupState_Null(uint256 streamId);
}
