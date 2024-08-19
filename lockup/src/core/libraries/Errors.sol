// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the admin.
    error CallerNotAdmin(address admin, address caller);

    /// @notice Thrown when trying to delegate call to a function that disallows delegate calls.
    error DelegateCall();

    /*//////////////////////////////////////////////////////////////////////////
                               LOCKUP-NFT-DESCRIPTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to generate the token URI for an unknown ERC-721 NFT contract.
    error LockupNFTDescriptor_UnknownNFT(IERC721Metadata nft, string symbol);

    /*//////////////////////////////////////////////////////////////////////////
                                   SABLIER-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to allow to hook a contract that doesn't implement the interface correctly.
    error SablierLockup_AllowToHookUnsupportedInterface(address recipient);

    /// @notice Thrown when trying to allow to hook an address with no code.
    error SablierLockup_AllowToHookZeroCodeSize(address recipient);

    /// @notice Thrown when the broker fee exceeds the maximum allowed fee.
    error SablierLockup_BrokerFeeTooHigh(UD60x18 brokerFee, UD60x18 maxBrokerFee);

    /// @notice Thrown when trying to create a stream with a zero deposit amount.
    error SablierLockup_DepositAmountZero();

    /// @notice Thrown when the hook does not return the correct selector.
    error SablierLockup_InvalidHookSelector(address recipient);

    /// @notice Thrown when trying to transfer Stream NFT when transferability is disabled.
    error SablierLockup_NotTransferable(uint256 tokenId);

    /// @notice Thrown when the ID references a null stream.
    error SablierLockup_Null(uint256 streamId);

    /// @notice Thrown when trying to withdraw an amount greater than the withdrawable amount.
    error SablierLockup_Overdraw(uint256 streamId, uint128 amount, uint128 withdrawableAmount);

    /// @notice Thrown when trying to create a stream with the sender as the zero address.
    error SablierLockup_SenderZeroAddress();

    /// @notice Thrown when trying to create a stream with a zero start time.
    error SablierLockup_StartTimeZero();

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

    /// @notice Thrown when `msg.sender` lacks authorization to perform an action.
    error SablierLockup_Unauthorized(uint256 streamId, address caller);

    /// @notice Thrown when trying to withdraw to an address other than the recipient's.
    error SablierLockup_WithdrawalAddressNotRecipient(uint256 streamId, address caller, address to);

    /// @notice Thrown when trying to withdraw zero assets from a stream.
    error SablierLockup_WithdrawAmountZero(uint256 streamId);

    /// @notice Thrown when trying to withdraw from multiple streams and the number of stream IDs does
    /// not match the number of withdraw amounts.
    error SablierLockup_WithdrawArrayCountsNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Thrown when trying to withdraw to the zero address.
    error SablierLockup_WithdrawToZeroAddress(uint256 streamId);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a stream with a deposit amount not equal to the sum of the
    /// segment amounts.
    error SablierLockupDynamic_DepositAmountNotEqualToSegmentAmountsSum(
        uint128 depositAmount, uint128 segmentAmountsSum
    );

    /// @notice Thrown when trying to create a stream with more segments than the maximum allowed.
    error SablierLockupDynamic_SegmentCountTooHigh(uint256 count);

    /// @notice Thrown when trying to create a stream with no segments.
    error SablierLockupDynamic_SegmentCountZero();

    /// @notice Thrown when trying to create a stream with unordered segment timestamps.
    error SablierLockupDynamic_SegmentTimestampsNotOrdered(
        uint256 index, uint40 previousTimestamp, uint40 currentTimestamp
    );

    /// @notice Thrown when trying to create a stream with a start time not strictly less than the first
    /// segment timestamp.
    error SablierLockupDynamic_StartTimeNotLessThanFirstSegmentTimestamp(uint40 startTime, uint40 firstSegmentTimestamp);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a stream with a cliff time not strictly less than the end time.
    error SablierLockupLinear_CliffTimeNotLessThanEndTime(uint40 cliffTime, uint40 endTime);

    /// @notice Thrown when trying to create a stream with a start time not strictly less than the cliff time, when the
    /// cliff time does not have a zero value.
    error SablierLockupLinear_StartTimeNotLessThanCliffTime(uint40 startTime, uint40 cliffTime);

    /// @notice Thrown when trying to create a stream with a start time not strictly less than the end time.
    error SablierLockupLinear_StartTimeNotLessThanEndTime(uint40 startTime, uint40 endTime);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-TRANCHE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a stream with a deposit amount not equal to the sum of the
    /// tranche amounts.
    error SablierLockupTranched_DepositAmountNotEqualToTrancheAmountsSum(
        uint128 depositAmount, uint128 trancheAmountsSum
    );

    /// @notice Thrown when trying to create a stream with a start time not strictly less than the first
    /// tranche timestamp.
    error SablierLockupTranched_StartTimeNotLessThanFirstTrancheTimestamp(
        uint40 startTime, uint40 firstTrancheTimestamp
    );

    /// @notice Thrown when trying to create a stream with more tranches than the maximum allowed.
    error SablierLockupTranched_TrancheCountTooHigh(uint256 count);

    /// @notice Thrown when trying to create a stream with no tranches.
    error SablierLockupTranched_TrancheCountZero();

    /// @notice Thrown when trying to create a stream with unordered tranche timestamps.
    error SablierLockupTranched_TrancheTimestampsNotOrdered(
        uint256 index, uint40 previousTimestamp, uint40 currentTimestamp
    );
}
