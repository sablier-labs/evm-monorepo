// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ClaimType } from "../types/MerkleBase.sol";

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                            SABLIER-FACTORY-MERKLE-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a campaign with native token.
    error SablierFactoryMerkleBase_ForbidNativeToken(address nativeToken);

    /// @notice Thrown when trying to set the native token address when it is already set.
    error SablierFactoryMerkleBase_NativeTokenAlreadySet(address nativeToken);

    /// @notice Thrown when trying to set zero address as native token.
    error SablierFactoryMerkleBase_NativeTokenZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                          SABLIER-FACTORY-MERKLE-EXECUTE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a merkle execute campaign with a target that is not a contract.
    error SablierFactoryMerkleExecute_TargetNotContract(address target);

    /*//////////////////////////////////////////////////////////////////////////
                             SABLIER-FACTORY-MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create an LT campaign with tranches' unlock percentages not adding up to 100%.
    error SablierFactoryMerkleLT_TotalPercentageNotOneHundred(uint64 totalPercentage);

    /*//////////////////////////////////////////////////////////////////////////
                             SABLIER-FACTORY-MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to create a Merkle VCA campaign with zero aggregate amount.
    error SablierFactoryMerkleVCA_AggregateAmountZero();

    /// @notice Thrown if expiration time is zero.
    error SablierFactoryMerkleVCA_ExpirationTimeZero();

    /// @notice Thrown if expiration time is within 1 week from the vesting end time.
    error SablierFactoryMerkleVCA_ExpirationTooEarly(uint40 vestingEndTime, uint40 expiration);

    /// @notice Thrown if the start time is zero.
    error SablierFactoryMerkleVCA_StartTimeZero();

    /// @notice Thrown if the unlock percentage is greater than 100%.
    error SablierFactoryMerkleVCA_UnlockPercentageTooHigh(UD60x18 unlockPercentage);

    /// @notice Thrown if vesting end time is not greater than the vesting start time.
    error SablierFactoryMerkleVCA_VestingEndTimeNotGreaterThanVestingStartTime(
        uint40 vestingStartTime,
        uint40 vestingEndTime
    );

    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER-MERKLE-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when caller is not the comptroller.
    error SablierMerkleBase_CallerNotComptroller(address comptroller, address caller);

    /// @notice Thrown when trying to claim after the campaign has expired.
    error SablierMerkleBase_CampaignExpired(uint256 blockTimestamp, uint40 expiration);

    /// @notice Thrown when trying to claim before the campaign start time.
    error SablierMerkleBase_CampaignNotStarted(uint256 blockTimestamp, uint40 campaignStartTime);

    /// @notice Thrown when trying to clawback when the current timestamp is over the grace period and the campaign has
    /// not expired.
    error SablierMerkleBase_ClawbackNotAllowed(uint256 blockTimestamp, uint40 expiration, uint40 firstClaimTime);

    /// @notice Thrown if fee transfer fails.
    error SablierMerkleBase_FeeTransferFailed(address feeRecipient, uint256 feeAmount);

    /// @notice Thrown when trying to claim the same index more than once.
    error SablierMerkleBase_IndexClaimed(uint256 index);

    /// @notice Thrown when trying to claim without paying the min fee.
    error SablierMerkleBase_InsufficientFeePayment(uint256 feePaid, uint256 minFeeWei);

    /// @notice Thrown when trying to claim with an invalid Merkle proof.
    error SablierMerkleBase_InvalidProof();

    /// @notice Thrown when trying to set a new min USD fee that is higher than the current fee.
    error SablierMerkleBase_NewMinFeeUSDNotLower(uint256 currentMinFeeUSD, uint256 newMinFeeUSD);

    /// @notice Thrown when trying to sponsor with a zero amount.
    error SablierMerkleBase_SponsorAmountZero();

    /// @notice Thrown when trying to claim to the zero address.
    error SablierMerkleBase_ToZeroAddress();

    /// @notice Thrown when trying to call a claim function not supported in the campaign.
    error SablierMerkleBase_UnsupportedClaimType(ClaimType claimTypeRequired, ClaimType claimTypeSupported);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-MERKLE-EXECUTE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the transferred amount is not equal to the claim amount during `claimAndExecute`.
    error SablierMerkleExecute_NotFullAmountTransferred(uint256 amountTransferred, uint256 claimAmount);

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-MERKLE-SIGNATURE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the attestation signature has expired.
    error SablierMerkleSignature_AttestationExpired(uint256 expireAt, uint256 blockTimestamp);

    /// @notice Thrown when the attestor returns the zero address.
    error SablierMerkleSignature_AttestorNotSet();

    /// @notice Thrown when caller is not the comptroller or campaign admin.
    error SablierMerkleSignature_CallerNotAuthorized(address caller, address campaignAdmin, address comptroller);

    /// @notice Thrown when claiming with an invalid EIP-712 or EIP-1271 signature.
    error SablierMerkleSignature_InvalidSignature();

    /// @notice Thrown when trying to claim with a signature that is not yet valid.
    error SablierMerkleSignature_SignatureNotYetValid(uint40 validFrom, uint40 blockTimestamp);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the claim amount is zero.
    error SablierMerkleVCA_ClaimAmountZero(address recipient);

    /// @notice Thrown when trying to switch to redistribute strategy when already using it.
    error SablierMerkleVCA_RedistributionAlreadyEnabled();

    /// @notice Thrown when trying to calculate the rewards amount without redistribution enabled.
    error SablierMerkleVCA_RedistributionNotEnabled();

    /// @notice Thrown when trying to enable redistribution after the vesting end time.
    error SablierMerkleVCA_VestingEndTimeNotInFuture(uint256 vestingEndTime, uint256 blockTimestamp);

    /// @notice Thrown when calculating the forgone amount with claim time less than the vesting start time.
    error SablierMerkleVCA_VestingNotStarted(uint40 claimTime, uint40 vestingStartTime);
}
