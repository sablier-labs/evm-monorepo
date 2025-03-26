// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierMerkleLockup } from "./ISablierMerkleLockup.sol";

/// @title ISablierMerkleLL
/// @notice MerkleLL enables an airdrop model with a vesting period powered by the Lockup Linear model.
interface ISablierMerkleLL is ISablierMerkleLockup {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    ///@notice Retrieves the cliff duration of the vesting stream, in seconds.
    function VESTING_CLIFF_DURATION() external view returns (uint40);

    /// @notice Retrieves the percentage of the claim amount due to be unlocked at the vesting cliff time, as a
    /// fixed-point number where 1e18 is 100%.
    function VESTING_CLIFF_UNLOCK_PERCENTAGE() external view returns (UD60x18);

    /// @notice Retrieves the start time of the vesting stream. Zero is a sentinel value for `block.timestamp`.
    function VESTING_START_TIME() external view returns (uint40);

    /// @notice Retrieves the percentage of the claim amount due to be unlocked at the vesting start time, as a
    /// fixed-point number where 1e18 is 100%.
    function VESTING_START_UNLOCK_PERCENTAGE() external view returns (UD60x18);

    /// @notice Retrieves the total duration of the vesting stream, in seconds.
    function VESTING_TOTAL_DURATION() external view returns (uint40);
}
