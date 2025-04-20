// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleLT } from "./../types/DataTypes.sol";
import { ISablierMerkleLockup } from "./ISablierMerkleLockup.sol";

/// @title ISablierMerkleLT
/// @notice MerkleLT enables an airdrop model with a vesting period powered by the Lockup Tranched model.
interface ISablierMerkleLT is ISablierMerkleLockup {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The total percentage of the tranches.
    function TOTAL_PERCENTAGE() external view returns (uint64);

    /// @notice Retrieves the start time of the vesting stream, as a Unix timestamp. Zero is a sentinel value for
    /// `block.timestamp`.
    function VESTING_START_TIME() external returns (uint40);

    /// @notice Retrieves the tranches with their respective unlock percentages and durations.
    function tranchesWithPercentages() external view returns (MerkleLT.TrancheWithPercentage[] memory);
}
