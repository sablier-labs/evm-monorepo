// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER-BATCH-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    error SablierBatchLockup_BatchSizeZero();

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-MERKLE-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to claim after the campaign has expired.
    error SablierMerkleLockup_CampaignExpired(uint256 blockTimestamp, uint40 expiration);

    /// @notice Thrown when trying to create a campaign with a name that is too long.
    error SablierMerkleLockup_CampaignNameTooLong(uint256 nameLength, uint256 maxLength);

    /// @notice Thrown when trying to clawback when the current timestamp is over the grace period and the campaign has
    /// not expired.
    error SablierMerkleLockup_ClawbackNotAllowed(uint256 blockTimestamp, uint40 expiration, uint40 firstClaimTime);

    /// @notice Thrown when trying to claim with an invalid Merkle proof.
    error SablierMerkleLockup_InvalidProof();

    /// @notice Thrown when trying to claim the same stream more than once.
    error SablierMerkleLockup_StreamClaimed(uint256 index);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to claim from an LT campaign with tranches' unlock percentages not adding up to 100%.
    error SablierMerkleLT_TotalPercentageNotOneHundred(uint64 totalPercentage);
}
