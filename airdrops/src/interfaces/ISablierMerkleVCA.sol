// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
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

    /// @notice Retrieves the percentage of the full amount that will unlock immediately at the start time. The
    /// value is denominated as a fixed-point number where 1e18 is 100%.
    function UNLOCK_PERCENTAGE() external view returns (UD60x18);

    /// @notice Retrieves the time when the VCA airdrop is fully vested, as a Unix timestamp.
    function VESTING_END_TIME() external view returns (uint40);

    /// @notice Retrieves the time when the VCA airdrop begins to unlock, as a Unix timestamp.
    function VESTING_START_TIME() external view returns (uint40);

    /// @notice Calculates the amount that would be claimed if the claim were made at `claimTime`.
    /// @dev This is for informational purposes only. To actually claim the airdrop, a Merkle proof is required.
    /// @param fullAmount The amount of tokens allocated to a user, denominated in the token's decimals.
    /// @param claimTime A hypothetical time at which to make the claim. Zero is a sentinel value for `block.timestamp`.
    /// @return The amount that would be claimed, denominated in the token's decimals.
    function calculateClaimAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128);

    /// @notice Calculates the amount that would be forgone if the claim were made at `claimTime`.
    /// @dev This is for informational purposes only. Returns zero if the claim time is less than the vesting start
    /// time, since the claim cannot be made, no amount can be forgone.
    /// @param fullAmount The amount of tokens allocated to a user, denominated in the token's decimals.
    /// @param claimTime A hypothetical time at which to make the claim. Zero is a sentinel value for `block.timestamp`.
    /// @return The amount that would be forgone, denominated in the token's decimals.
    function calculateForgoneAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128);

    /// @notice Retrieves the total amount of tokens forgone by early claimers.
    function totalForgoneAmount() external view returns (uint256);
}
