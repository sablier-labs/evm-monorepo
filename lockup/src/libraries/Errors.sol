// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @title Errors
/// @notice Library containing all the custom errors the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the caller is not the admin.
    error CallerNotAdmin(address admin, address caller);

    /// @notice Thrown when trying to delegate call to a function that disallows delegate calls.
    error DelegateCall();

    /*//////////////////////////////////////////////////////////////////////////
                                  SABLIER-V2-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to claim protocol revenues for an asset with no accrued revenues.
    error SablierV2Base_NoProtocolRevenues(IERC20 asset);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to flash loan an amount greater than or equal to 2^128.
    error SablierV2FlashLoan_AmountTooHigh(uint256 amount);

    /// @notice Thrown when trying to flash loan an unsupported asset.
    error SablierV2FlashLoan_AssetNotFlashLoanable(IERC20 asset);

    /// @notice Thrown when the calculated fee during a flash loan is greater than or equal to 2^128.
    error SablierV2FlashLoan_CalculatedFeeTooHigh(uint256 amount);

    /// @notice Thrown when the callback to the flash borrower fails.
    error SablierV2FlashLoan_FlashBorrowFail();

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the broker fee exceeds the maximum allowed fee.
    error SablierV2Lockup_BrokerFeeTooHigh(UD60x18 brokerFee, UD60x18 maxFee);

    /// @notice Thrown when trying to create a stream with a zero deposit amount.
    error SablierV2Lockup_DepositAmountZero();

    /// @notice Thrown when trying to create a stream with an end time in the past.
    error SablierV2Lockup_EndTimeInThePast(uint40 currentTime, uint40 endTime);

    /// @notice Thrown when the protocol fee exceeds the maximum allowed fee.
    error SablierV2Lockup_ProtocolFeeTooHigh(UD60x18 protocolFee, UD60x18 maxFee);

    /// @notice Thrown when trying to withdraw from a depleted stream.
    error SablierV2Lockup_StreamDepleted(uint256 streamId);

    /// @notice Thrown when trying to cancel or renounce a stream that is not cancelable.
    error SablierV2Lockup_StreamNotCancelable(uint256 streamId);

    /// @notice Thrown when an action requires the stream to be active.
    error SablierV2Lockup_StreamNotActive(uint256 streamId);

    /// @notice Thrown when trying to burn a stream that is not depleted.
    error SablierV2Lockup_StreamNotDepleted(uint256 streamId);

    /// @notice Thrown when trying to interact with a null stream.
    error SablierV2Lockup_StreamNull(uint256 streamId);

    /// @notice Thrown when trying to cancel a settled streams, i.e. an active stream from which the
    /// sender cannot recover any more assets.
    error SablierV2Lockup_StreamSettled(uint256 streamId);

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierV2Lockup_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to withdraw more than the withdrawable amount.
    error SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount(
        uint256 streamId, uint128 amount, uint128 withdrawableAmount
    );

    /// @notice Thrown when trying to withdraw zero assets from a stream.
    error SablierV2Lockup_WithdrawAmountZero(uint256 streamId);

    /// @notice Thrown when trying to withdraw from multiple streams and the number of stream ids does
    /// not match the number of withdraw amounts.
    error SablierV2Lockup_WithdrawArrayCountsNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Thrown when the stream's sender tries to withdraw to an address other than the recipient's.
    error SablierV2Lockup_WithdrawSenderUnauthorized(uint256 streamId, address sender, address to);

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierV2Lockup_WithdrawToZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                             SABLIER-V2-LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a dynamic stream with a deposit amount not equal to the sum of the
    /// segment amounts.
    error SablierV2LockupDynamic_DepositAmountNotEqualToSegmentAmountsSum(
        uint128 depositAmount, uint128 segmentAmountsSum
    );

    /// @notice Thrown when trying to create a dynamic stream with more segments than the maximum allowed.
    error SablierV2LockupDynamic_SegmentCountTooHigh(uint256 count);

    /// @notice Thrown when trying to create a dynamic stream with no segments.
    error SablierV2LockupDynamic_SegmentCountZero();

    /// @notice Thrown when trying to create a dynamic stream with unordered segment milestones.
    error SablierV2LockupDynamic_SegmentMilestonesNotOrdered(
        uint256 index, uint40 previousMilestone, uint40 currentMilestone
    );

    /// segment milestone.
    /// @notice Thrown when trying to create a stream with a start time not strictly less than the first
    /// segment milestone.
    error SablierV2LockupDynamic_StartTimeNotLessThanFirstSegmentMilestone(
        uint40 startTime, uint40 firstSegmentMilestone
    );

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-V2-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a linear stream with a cliff time not strictly less than the end time.
    error SablierV2LockupLinear_CliffTimeNotLessThanEndTime(uint40 cliffTime, uint40 endTime);

    /// @notice Thrown when trying to create a linear stream with a start time greater than the cliff time.
    error SablierV2LockupLinear_StartTimeGreaterThanCliffTime(uint40 startTime, uint40 cliffTime);
}
