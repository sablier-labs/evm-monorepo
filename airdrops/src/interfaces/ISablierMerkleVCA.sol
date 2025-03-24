// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleVCA } from "../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleVCA
/// @notice VCA stands for Variable Claim Amount, and is an airdrop model where the claim amount increases linearly
/// until the airdrop period ends. Claiming early results in forgoing the remaining amount, whereas claiming after the
/// period grants the full amount that was allocated.
interface ISablierMerkleVCA is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims the airdrop.
    event Claim(uint256 index, address indexed recipient, uint128 claimAmount, uint128 forgoneAmount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the amount that would be claimed if the claim were made at `claimTime`.
    /// @dev This is for informational purposes only. To actually claim the airdrop, a Merkle proof is required.
    /// @param fullAmount The amount of tokens allocated to a user, denominated in the token's decimals.
    /// @param claimTime A hypothetical time at which to make the claim. Zero is a sentinel value for `block.timestamp`.
    function calculateClaimAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128);

    /// @notice Calculates the amount that would be forgone if the claim were made at `claimTime`.
    /// @dev This is for informational purposes only. To actually claim the airdrop, a Merkle proof is required.
    /// @param fullAmount The amount of tokens allocated to a user, denominated in the token's decimals.
    /// @param claimTime A hypothetical time at which to make the claim. Zero is a sentinel value for `block.timestamp`.
    function calculateForgoneAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128);

    /// @notice Retrieves the start time and end time of the vesting schedule.
    function getSchedule() external view returns (MerkleVCA.Schedule memory);

    /// @notice Retrieves the total amount of tokens forgone by early claimers.
    function totalForgoneAmount() external view returns (uint256);
}
