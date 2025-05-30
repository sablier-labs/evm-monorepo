// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER-MERKLE-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when caller is not the factory contract.
    error SablierMerkleBase_CallerNotFactory(address factory, address caller);

    /// @notice Thrown when caller is not the factory admin.
    error SablierMerkleBase_CallerNotFactoryAdmin(address factoryAdmin, address caller);

    /// @notice Thrown when trying to claim after the campaign has expired.
    error SablierMerkleBase_CampaignExpired(uint256 blockTimestamp, uint40 expiration);

    /// @notice Thrown when trying to claim before the campaign start time.
    error SablierMerkleBase_CampaignNotStarted(uint256 blockTimestamp, uint40 campaignStartTime);

    /// @notice Thrown when trying to clawback when the current timestamp is over the grace period and the campaign has
    /// not expired.
    error SablierMerkleBase_ClawbackNotAllowed(uint256 blockTimestamp, uint40 expiration, uint40 firstClaimTime);

    /// @notice Thrown if the fees withdrawal failed.
    error SablierMerkleBase_FeeTransferFail(address feeRecipient, uint256 feeAmount);

    /// @notice Thrown when trying to claim the same index more than once.
    error SablierMerkleBase_IndexClaimed(uint256 index);

    /// @notice Thrown when trying to claim without paying the min fee.
    error SablierMerkleBase_InsufficientFeePayment(uint256 feePaid, uint256 minFeeWei);

    /// @notice Thrown when trying to claim with an invalid Merkle proof.
    error SablierMerkleBase_InvalidProof();

    /// @notice Thrown when trying to set a new min USD fee that is higher than the current fee.
    error SablierMerkleBase_NewMinFeeUSDNotLower(uint256 currentMinFeeUSD, uint256 newMinFeeUSD);

    /*//////////////////////////////////////////////////////////////////////////
                            SABLIER-MERKLE-FACTORY-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when an unauthorized address collects fee without setting the fee recipient to admin address.
    error SablierMerkleFactoryBase_FeeRecipientNotAdmin(address feeRecipient, address admin);

    /// @notice Thrown when trying to create a campaign with native token.
    error SablierFactoryMerkleBase_ForbidNativeToken(address nativeToken);

    /// @notice Thrown when trying to set fee to a value that exceeds the maximum USD fee.
    error SablierFactoryMerkleBase_MaxFeeUSDExceeded(uint256 newFeeUSD, uint256 maxFeeUSD);

    /// @notice Thrown when trying to set the native token address when it is already set.
    error SablierFactoryMerkleBase_NativeTokenAlreadySet(address nativeToken);

    /// @notice Thrown when trying to set zero address as native token.
    error SablierFactoryMerkleBase_NativeTokenZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to claim to the zero address.
    error SablierMerkleInstant_ToZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to claim to the zero address.
    error SablierMerkleLL_ToZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to claim from an LT campaign with tranches' unlock percentages not adding up to 100%.
    error SablierMerkleLT_TotalPercentageNotOneHundred(uint64 totalPercentage);

    /// @notice Thrown when trying to claim to the zero address.
    error SablierMerkleLT_ToZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the claim amount is zero.
    error SablierMerkleVCA_ClaimAmountZero(address recipient);

    /// @notice Thrown if expiration time is within 1 week from the vesting end time.
    error SablierMerkleVCA_ExpirationTooEarly(uint40 vestingEndTime, uint40 expiration);

    /// @notice Thrown if expiration time is zero.
    error SablierMerkleVCA_ExpirationTimeZero();

    /// @notice Thrown if vesting end time is not greater than the vesting start time.
    error SablierMerkleVCA_VestingEndTimeNotGreaterThanVestingStartTime(uint40 vestingStartTime, uint40 vestingEndTime);

    /// @notice Thrown if the start time is zero.
    error SablierMerkleVCA_StartTimeZero();

    /// @notice Thrown when trying to claim to the zero address.
    error SablierMerkleVCA_ToZeroAddress();

    /// @notice Thrown if the unlock percentage is greater than 100%.
    error SablierMerkleVCA_UnlockPercentageTooHigh(UD60x18 unlockPercentage);
}
