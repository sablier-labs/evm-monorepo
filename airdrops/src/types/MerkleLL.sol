// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ClaimType } from "./MerkleBase.sol";

library MerkleLL {
    /// @notice Struct encapsulating the constructor parameters of Merkle Lockup Linear campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param cancelable Indicates if the Lockup stream will be cancelable after claiming.
    /// @param claimType The type of claim functions supported by the campaign.
    /// @param cliffDuration The cliff duration of the vesting stream, in seconds.
    /// @param cliffUnlockPercentage The percentage of the claim amount due to be unlocked at the vesting cliff time, as
    /// a fixed-point number where 1e18 is 100%.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param granularity The smallest step in time between two consecutive token unlocks. Zero is a sentinel value for
    /// 1 second.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS. An empty value may break certain UI
    /// features that depend upon the IPFS CID.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param shape The shape of the vesting stream, used for differentiating between streams in the UI.
    /// @param startUnlockPercentage The percentage of the claim amount due to be unlocked at the vesting start time, as
    /// a fixed-point number where 1e18 is 100%.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param totalDuration The total duration of the vesting stream, in seconds.
    /// @param transferable Indicates if the Lockup stream will be transferable after claiming.
    /// @param vestingStartTime The start time of the vesting stream, as a Unix timestamp. Zero is a sentinel value for
    /// `block.timestamp`.
    struct ConstructorParams {
        string campaignName;
        uint40 campaignStartTime;
        bool cancelable;
        ClaimType claimType;
        uint40 cliffDuration;
        UD60x18 cliffUnlockPercentage;
        uint40 expiration;
        uint40 granularity;
        address initialAdmin;
        string ipfsCID;
        ISablierLockup lockup;
        bytes32 merkleRoot;
        string shape;
        UD60x18 startUnlockPercentage;
        IERC20 token;
        uint40 totalDuration;
        bool transferable;
        uint40 vestingStartTime;
    }
}
