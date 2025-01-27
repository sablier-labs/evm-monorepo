// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Lockup } from "../types/DataTypes.sol";

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
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
                                SABLIER-BATCH-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    error SablierBatchLockup_BatchSizeZero();

    /*//////////////////////////////////////////////////////////////////////////
                               LOCKUP-NFT-DESCRIPTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to generate the token URI for an unknown ERC-721 NFT contract.
    error LockupNFTDescriptor_UnknownNFT(IERC721Metadata nft, string symbol);

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the broker fee exceeds the maximum allowed fee.
    error SablierHelpers_BrokerFeeTooHigh(UD60x18 brokerFee, UD60x18 maxBrokerFee);

    /// @notice Thrown when trying to create a linear stream with a cliff time not strictly less than the end time.
    error SablierHelpers_CliffTimeNotLessThanEndTime(uint40 cliffTime, uint40 endTime);

    /// @notice Thrown when trying to create a stream with a non zero cliff unlock amount when the cliff time is zero.
    error SablierHelpers_CliffTimeZeroUnlockAmountNotZero(uint128 cliffUnlockAmount);

    /// @notice Thrown when trying to create a dynamic stream with a deposit amount not equal to the sum of the segment
    /// amounts.
    error SablierHelpers_DepositAmountNotEqualToSegmentAmountsSum(uint128 depositAmount, uint128 segmentAmountsSum);

    /// @notice Thrown when trying to create a tranched stream with a deposit amount not equal to the sum of the tranche
    /// amounts.
    error SablierHelpers_DepositAmountNotEqualToTrancheAmountsSum(uint128 depositAmount, uint128 trancheAmountsSum);

    /// @notice Thrown when trying to create a stream with a zero deposit amount.
    error SablierHelpers_DepositAmountZero();

    /// @notice Thrown when trying to create a dynamic stream with end time not equal to the last segment's timestamp.
    error SablierHelpers_EndTimeNotEqualToLastSegmentTimestamp(uint40 endTime, uint40 lastSegmentTimestamp);

    /// @notice Thrown when trying to create a tranched stream with end time not equal to the last tranche's timestamp.
    error SablierHelpers_EndTimeNotEqualToLastTrancheTimestamp(uint40 endTime, uint40 lastTrancheTimestamp);

    /// @notice Thrown when trying to create a dynamic stream with more segments than the maximum allowed.
    error SablierHelpers_SegmentCountTooHigh(uint256 count);

    /// @notice Thrown when trying to create a dynamic stream with no segments.
    error SablierHelpers_SegmentCountZero();

    /// @notice Thrown when trying to create a dynamic stream with unordered segment timestamps.
    error SablierHelpers_SegmentTimestampsNotOrdered(uint256 index, uint40 previousTimestamp, uint40 currentTimestamp);

    /// @notice Thrown when trying to create a stream with the sender as the zero address.
    error SablierHelpers_SenderZeroAddress();

    /// @notice Thrown when trying to create a stream with a shape string exceeding 32 bytes.
    error SablierHelpers_ShapeExceeds32Bytes(uint256 shapeLength);

    /// @notice Thrown when trying to create a linear stream with a start time not strictly less than the cliff time,
    /// when the cliff time does not have a zero value.
    error SablierHelpers_StartTimeNotLessThanCliffTime(uint40 startTime, uint40 cliffTime);

    /// @notice Thrown when trying to create a linear stream with a start time not strictly less than the end time.
    error SablierHelpers_StartTimeNotLessThanEndTime(uint40 startTime, uint40 endTime);

    /// @notice Thrown when trying to create a dynamic stream with a start time not strictly less than the first
    /// segment timestamp.
    error SablierHelpers_StartTimeNotLessThanFirstSegmentTimestamp(uint40 startTime, uint40 firstSegmentTimestamp);

    /// @notice Thrown when trying to create a tranched stream with a start time not strictly less than the first
    /// tranche timestamp.
    error SablierHelpers_StartTimeNotLessThanFirstTrancheTimestamp(uint40 startTime, uint40 firstTrancheTimestamp);

    /// @notice Thrown when trying to create a stream with a zero start time.
    error SablierHelpers_StartTimeZero();

    /// @notice Thrown when trying to create a tranched stream with more tranches than the maximum allowed.
    error SablierHelpers_TrancheCountTooHigh(uint256 count);

    /// @notice Thrown when trying to create a tranched stream with no tranches.
    error SablierHelpers_TrancheCountZero();

    /// @notice Thrown when trying to create a tranched stream with unordered tranche timestamps.
    error SablierHelpers_TrancheTimestampsNotOrdered(uint256 index, uint40 previousTimestamp, uint40 currentTimestamp);

    /// @notice Thrown when trying to create a stream with the sum of the unlock amounts greater than the deposit
    /// amount.
    error SablierHelpers_UnlockAmountsSumTooHigh(
        uint128 depositAmount, uint128 startUnlockAmount, uint128 cliffUnlockAmount
    );

    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER-LOCKUP-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to allow to hook a contract that doesn't implement the interface correctly.
    error SablierLockupBase_AllowToHookUnsupportedInterface(address recipient);

    /// @notice Thrown when trying to allow to hook an address with no code.
    error SablierLockupBase_AllowToHookZeroCodeSize(address recipient);

    /// @notice Thrown when the fee transfer fails.
    error SablierLockupBase_FeeTransferFail(address admin, uint256 feeAmount);

    /// @notice Thrown when the hook does not return the correct selector.
    error SablierLockupBase_InvalidHookSelector(address recipient);

    /// @notice Thrown when trying to transfer Stream NFT when transferability is disabled.
    error SablierLockupBase_NotTransferable(uint256 tokenId);

    /// @notice Thrown when the ID references a null stream.
    error SablierLockupBase_Null(uint256 streamId);

    /// @notice Thrown when trying to withdraw an amount greater than the withdrawable amount.
    error SablierLockupBase_Overdraw(uint256 streamId, uint128 amount, uint128 withdrawableAmount);

    /// @notice Thrown when trying to cancel or renounce a canceled stream.
    error SablierLockupBase_StreamCanceled(uint256 streamId);

    /// @notice Thrown when trying to cancel, renounce, or withdraw from a depleted stream.
    error SablierLockupBase_StreamDepleted(uint256 streamId);

    /// @notice Thrown when trying to cancel or renounce a stream that is not cancelable.
    error SablierLockupBase_StreamNotCancelable(uint256 streamId);

    /// @notice Thrown when trying to burn a stream that is not depleted.
    error SablierLockupBase_StreamNotDepleted(uint256 streamId);

    /// @notice Thrown when trying to cancel or renounce a settled stream.
    error SablierLockupBase_StreamSettled(uint256 streamId);

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierLockupBase_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to withdraw to an address other than the recipient's.
    error SablierLockupBase_WithdrawalAddressNotRecipient(uint256 streamId, address caller, address to);

    /// @notice Thrown when trying to withdraw zero tokens from a stream.
    error SablierLockupBase_WithdrawAmountZero(uint256 streamId);

    /// @notice Thrown when trying to withdraw from multiple streams and the number of stream IDs does
    /// not match the number of withdraw amounts.
    error SablierLockupBase_WithdrawArrayCountsNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierLockupBase_WithdrawToZeroAddress(uint256 streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                    SABLIER-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a function is called on a stream that does not use the expected Lockup model.
    error SablierLockup_NotExpectedModel(Lockup.Model actualLockupModel, Lockup.Model expectedLockupModel);
}
