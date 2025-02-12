// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleLL } from "./../types/DataTypes.sol";
import { ISablierMerkleLockup } from "./ISablierMerkleLockup.sol";

/// @title ISablierMerkleLL
/// @notice MerkleLL enables airdrops with a vesting period powered by the Lockup Linear distribution model.
interface ISablierMerkleLL is ISablierMerkleLockup {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice A tuple containing the start time, start unlock percentage, cliff duration, cliff unlock percentage, and
    /// end duration. These values are used to calculate the vesting schedule in `Lockup.CreateWithTimestampsLL`.
    /// @dev A start time value of zero will be considered as `block.timestamp`.
    function getSchedule() external view returns (MerkleLL.Schedule memory);
}
