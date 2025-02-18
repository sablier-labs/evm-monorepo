// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleVCA } from "../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleVCA
/// @notice MerkleVCA enables airdrop distributions where the claimable amount linearly increases over time. If the
/// claim is made at the end of the designated period, the recipient receives the full airdrop allocation.
interface ISablierMerkleVCA is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims the airdrop.
    event Claim(uint256 index, address indexed recipient, uint128 claimableAmount, uint128 totalAmount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the amount of tokens forgone by the early claimers.
    function forgoneAmount() external view returns (uint256);

    /// @notice Returns the start time and end time of the airdrop unlock.
    function timestamps() external view returns (MerkleVCA.Timestamps memory);
}
