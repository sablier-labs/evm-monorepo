// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD59x18 } from "@prb/math/SD59x18.sol";

/// @title Errors
/// @notice Library with custom errors used across the core contracts.
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

    /// @notice Emitted when attempting to cancel a stream that is already non-cancelable.
    error SablierV2__StreamNonCancelable(uint256 streamId);

    /// @notice Emitted when the stream id points to a nonexistent stream.
    error SablierV2__StreamNonExistent(uint256 streamId);

    /// @notice Emitted when the caller is not authorized to perform some action.
    error SablierV2__Unauthorized(uint256 streamId, address caller);

    /// @notice Emitted when attempting to withdraw from multiple streams and the count of the stream ids does
    /// not match the count of the amounts.
    error SablierV2__WithdrawAllArraysNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Emitted when attempting to withdraw more than can be withdrawn.
    error SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(
        uint256 streamId,
        uint128 withdrawAmount,
        uint128 withdrawableAmount
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
    error SablierV2Linear__StartTimeGreaterThanCliffTime(uint40 startTime, uint40 cliffTime);

    /// @notice Emitted when attempting to create a stream with a cliff time greater than stop time;
    error SablierV2Linear__CliffTimeGreaterThanStopTime(uint40 cliffTime, uint40 stopTime);

    /*//////////////////////////////////////////////////////////////////////////
                            SABLIER-V2-PRO CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when attempting to create a stream with a deposit amount that does not qual the segment
    /// amounts sum.
    error SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum(uint128 depositAmount, uint128 segmentAmountsSum);

    /// @notice Emitted when attempting to create a stream with segment counts that are not equal.
    error SablierV2Pro__SegmentCountsNotEqual(uint256 amountsCount, uint256 exponentsCount, uint256 milestonesCount);

    /// @notice Emitted when attempting to create a stream with one or more out-of-bounds segment count.
    error SablierV2Pro__SegmentCountOutOfBounds(uint256 count);

    /// @notice Emitted when attempting to create a stream with zero segments.
    error SablierV2Pro__SegmentCountZero();

    /// @notice Emitted when attempting to create a stream with an out of bounds exponent.
    error SablierV2Pro__SegmentExponentOutOfBounds(SD59x18 exponent);

    /// @notice Emitted when attempting to create a stream with segment milestones that are not ordered.
    error SablierV2Pro__SegmentMilestonesNotOrdered(uint256 index, uint40 previousMilestone, uint40 currentMilestone);

    /// @notice Emitted when attempting to create a stream with the start time greater than the first segment milestone.
    error SablierV2Pro__StartTimeGreaterThanFirstMilestone(uint40 startTime, uint40 segmentMilestone);
}
