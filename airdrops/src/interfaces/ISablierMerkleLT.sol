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

    /// @notice The start time of the streams created through {SablierMerkleBase.claim} function.
    /// @dev A start time value of zero will be treated as `block.timestamp`.
    function STREAM_START_TIME() external returns (uint40);

    /// @notice The total percentage of the tranches.
    function TOTAL_PERCENTAGE() external view returns (uint64);

    /// @notice Retrieves the tranches with their respective unlock percentages and durations.
    function getTranchesWithPercentages() external view returns (MerkleLT.TrancheWithPercentage[] memory);
}
