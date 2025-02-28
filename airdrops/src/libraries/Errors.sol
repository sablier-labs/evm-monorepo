// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

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

    /// @notice Thrown when trying to clawback when the current timestamp is over the grace period and the campaign has
    /// not expired.
    error SablierMerkleBase_ClawbackNotAllowed(uint256 blockTimestamp, uint40 expiration, uint40 firstClaimTime);

    /// @notice Thrown if the fees withdrawal failed.
    error SablierMerkleBase_FeeTransferFail(address factoryAdmin, uint256 feeAmount);

    /// @notice Thrown when trying to claim with an insufficient fee payment.
    error SablierMerkleBase_InsufficientFeePayment(uint256 feePaid, uint256 fee);

    /// @notice Thrown when trying to claim with an invalid Merkle proof.
    error SablierMerkleBase_InvalidProof();

    /// @notice Thrown when trying to set a fee that is higher than the current fee.
    error SablierMerkleBase_NewFeeHigher(uint256 currentFee, uint256 newFee);

    /// @notice Thrown when trying to claim the same stream more than once.
    error SablierMerkleBase_StreamClaimed(uint256 index);

    /*//////////////////////////////////////////////////////////////////////////
                            SABLIER-MERKLE-FACTORY-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to set fee to a value that exceeds the maximum fee.
    error SablierMerkleFactoryBase_MaximumFeeExceeded(uint256 newFee, uint256 maxFee);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to claim from an LT campaign with tranches' unlock percentages not adding up to 100%.
    error SablierMerkleLT_TotalPercentageNotOneHundred(uint64 totalPercentage);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown while claiming when unlock start time is in the future.
    error SablierMerkleVCA_ClaimNotStarted(uint40 startTime);

    /// @notice Thrown if expiry of a VCA campaign is zero.
    error SablierMerkleVCA_ExpiryTimeZero();

    /// @notice Thrown if expiry of a VCA campaign is within 1 week from the unlock end time.
    error SablierMerkleVCA_ExpiryWithinOneWeekOfUnlockEndTime(uint40 endTime, uint40 expiration);

    /// @notice Thrown if end time of unlock is less than the start time.
    error SablierMerkleVCA_StartTimeExceedsEndTime(uint40 startTime, uint40 endTime);

    /// @notice Thrown if the unlock start time is zero.
    error SablierMerkleVCA_StartTimeZero();
}
