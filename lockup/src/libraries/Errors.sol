// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @title Errors
/// @notice Library that contains all the custom errors that the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the caller is not the admin.
    error CallerNotAdmin(address admin, address caller);

    /// @notice Thrown when attempting to delegate call to a function that does not allow delegate calls.
    error DelegateCall();

    /*//////////////////////////////////////////////////////////////////////////
                                  SABLIER-V2-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to claim protocol revenues for an asset that did not accrue any revenues.
    error SablierV2Base_NoProtocolRevenues(IERC20 asset);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to flash loan an amount that is greater than or equal to 2^128.
    error SablierV2FlashLoan_AmountTooHigh(uint256 amount);

    /// @notice Thrown when attempting to flash loan an asset that is not supported.
    error SablierV2FlashLoan_AssetNotFlashLoanable(IERC20 asset);

    /// @notice Thrown when during a flash loan the calculated fee is greater than or equal to 2^128.
    error SablierV2FlashLoan_CalculatedFeeTooHigh(uint256 amount);

    /// @notice Thrown when the callback to the flash borrower failed.
    error SablierV2FlashLoan_FlashBorrowFail();

    /// @notice Thrown when attempting to flash loan more than is available for lending.
    error SablierV2FlashLoan_InsufficientAssetLiquidity(IERC20 asset, uint256 amountAvailable, uint256 amountRequested);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the broker fee is greater than the maximum fee permitted.
    error SablierV2Lockup_BrokerFeeTooHigh(UD60x18 brokerFee, UD60x18 maxFee);

    /// @notice Thrown when attempting to create a stream with a zero deposit amount.
    error SablierV2Lockup_DepositAmountZero();

    /// @notice Thrown when the protocol fee is greater than the maximum fee permitted.
    error SablierV2Lockup_ProtocolFeeTooHigh(UD60x18 protocolFee, UD60x18 maxFee);

    /// @notice Thrown when attempting to cancel a stream that is already non-cancelable.
    error SablierV2Lockup_StreamNonCancelable(uint256 streamId);

    /// @notice Thrown when the stream id points to a stream that is not active.
    error SablierV2Lockup_StreamNotActive(uint256 streamId);

    /// @notice Thrown when the stream id points to a stream that is not canceled or depleted.
    error SablierV2Lockup_StreamNotCanceledOrDepleted(uint256 streamId);

    /// @notice Thrown when attempting to interact with a null stream.
    error SablierV2Lockup_StreamNull(uint256 streamId);

    /// @notice Thrown when the `msg.sender` is not authorized to perform some action.
    error SablierV2Lockup_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when attempting to withdraw more than can be withdrawn.
    error SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount(
        uint256 streamId, uint128 amount, uint128 withdrawableAmount
    );

    /// @notice Thrown when attempting to withdraw zero assets from a stream.
    /// @notice The id of the stream.
    error SablierV2Lockup_WithdrawAmountZero(uint256 streamId);

    /// @notice Thrown when attempting to withdraw from multiple streams and the count of the stream ids does
    /// not match the count of the amounts.
    error SablierV2Lockup_WithdrawArrayCountsNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Thrown when the sender of the stream attempts to withdraw to some address other than the recipient.
    error SablierV2Lockup_WithdrawSenderUnauthorized(uint256 streamId, address sender, address to);

    /// @notice Thrown when attempting to withdraw to a zero address.
    error SablierV2Lockup_WithdrawToZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-V2-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to create a stream with a cliff time that is not strictly less than the
    /// end time.
    error SablierV2LockupLinear_CliffTimeNotLessThanEndTime(uint40 cliffTime, uint40 endTime);

    /// @notice Thrown when attempting to create a stream with a start time greater than the cliff time.
    error SablierV2LockupLinear_StartTimeGreaterThanCliffTime(uint40 startTime, uint40 cliffTime);

    /*//////////////////////////////////////////////////////////////////////////
                             SABLIER-V2-LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to create a stream with a deposit amount that does not equal the segment
    /// amounts sum.
    error SablierV2LockupDynamic_DepositAmountNotEqualToSegmentAmountsSum(
        uint128 depositAmount, uint128 segmentAmountsSum
    );

    /// @notice Thrown when attempting to create a stream with more segments than the maximum permitted.
    error SablierV2LockupDynamic_SegmentCountTooHigh(uint256 count);

    /// @notice Thrown when attempting to create a stream with zero segments.
    error SablierV2LockupDynamic_SegmentCountZero();

    /// @notice Thrown when attempting to create a stream with segment milestones that are not ordered.
    error SablierV2LockupDynamic_SegmentMilestonesNotOrdered(
        uint256 index, uint40 previousMilestone, uint40 currentMilestone
    );

    /// @notice Thrown when attempting to create a stream with a start time that is not strictly less than the first
    /// segment milestone.
    error SablierV2LockupDynamic_StartTimeNotLessThanFirstSegmentMilestone(
        uint40 startTime, uint40 firstSegmentMilestone
    );
}
