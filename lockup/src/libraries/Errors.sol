// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD59x18 } from "@prb/math/SD59x18.sol";

/// @title Errors
/// @author Sablier Labs Ltd.
/// @notice Library with custom erros used across the core.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-V2 CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Emitted when attempting to create a stream with a zero deposit amount.
    error SablierV2__DepositAmountZero();

    /// @notice Emitted when attempting to create a stream with the recipient as the zero address.
    error SablierV2__RecipientZeroAddress();

    /// @notice Emitted when attempting to renounce an already non-cancelable stream.
    error SablierV2__RenounceNonCancelableStream(uint256 streamId);

    /// @notice Emitted when attempting to create a stream with the sender as the zero address.
    error SablierV2__SenderZeroAddress();

    /// @notice Emitted when attempting to create a stream with the start time greater than the stop time.
    error SablierV2__StartTimeGreaterThanStopTime(uint64 startTime, uint64 stopTime);

    /// @notice Emitted when attempting to cancel a stream that is already non-cancelable.
    error SablierV2__StreamNonCancelable(uint256 streamId);

    /// @notice Emitted when the stream id points to a nonexistent stream.
    error SablierV2__StreamNonExistent(uint256 streamId);

    /// @notice Emitted when the caller is not authorized to perform some action.
    error SablierV2__Unauthorized(uint256 streamId, address caller);

    /// @notice Emitted when attempting to withdraw from multiple streams and the count of the stream ids does
    /// not match the count of the amounts.
    error SablierV2__WithdrawAllArraysNotEqual(uint256 streamIdsLength, uint256 amountsLength);

    /// @notice Emitted when attempting to withdraw more than can be withdrawn.
    error SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(
        uint256 streamId,
        uint256 withdrawAmount,
        uint256 withdrawableAmount
    );

    /// @notice Emitted when attempting to withdraw zero tokens from a stream.
    /// @notice The id of the stream.
    error SablierV2__WithdrawAmountZero(uint256 streamId);

    /// @notice Emitted when attempting to withdraw to a zero address.
    error SablierV2__WithdrawZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                           SABLIER-V2-LINEAR CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when attempting to create a stream with a start time greater than cliff time;
    error SablierV2Linear__StartTimeGreaterThanCliffTime(uint64 startTime, uint64 cliffTime);

    /// @notice Emitted when attempting to create a stream with a cliff time greater than stop time;
    error SablierV2Linear__CliffTimeGreaterThanStopTime(uint64 cliffTime, uint64 stopTime);

    /*//////////////////////////////////////////////////////////////////////////
                            SABLIER-V2-PRO CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when attempting to create a stream with a deposit amount that does not qual the segment
    /// amounts sum.
    error SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum(uint256 depositAmount, uint256 segmentAmountsSum);

    /// @notice Emitted when attempting to create a stream with segment counts that are not equal.
    error SablierV2Pro__SegmentCountsNotEqual(uint256 amountLength, uint256 exponentLength, uint256 milestoneLength);

    /// @notice Emitted when attempting to create a stream with one or more out-of-bounds segment count.
    error SablierV2Pro__SegmentCountOutOfBounds(uint256 count);

    /// @notice Emitted when attempting to create a stream with zero segments.
    error SablierV2Pro__SegmentCountZero();

    /// @notice Emitted when attempting to create a stream with an out of bounds exponent.
    error SablierV2Pro__SegmentExponentOutOfBounds(SD59x18 exponent);

    /// @notice Emitted when attempting to create a stream with segment milestones which are not ordered.
    error SablierV2Pro__SegmentMilestonesNotOrdered(uint256 index, uint64 previousMilestonene, uint64 milestone);

    /// @notice Emitted when attempting to create a stream with the start time greater than the first segment milestone.
    error SablierV2Pro__StartTimeGreaterThanFirstMilestone(uint64 startTime, uint64 segmentMilestone);
}
