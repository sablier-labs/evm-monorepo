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

    /// @notice Retrieves the start time of the vesting stream, as a Unix timestamp. Zero is a sentinel value for
    /// `block.timestamp`.
    function VESTING_START_TIME() external view returns (uint40);

    /// @notice Retrieves the percentage of the claim amount due to be unlocked at the vesting start time, as a
    /// fixed-point number where 1e18 is 100%.
    function VESTING_START_UNLOCK_PERCENTAGE() external view returns (UD60x18);

    /// @notice Retrieves the total duration of the vesting stream, in seconds.
    function VESTING_TOTAL_DURATION() external view returns (uint40);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Makes the claim. If the vesting end time is in the future, it creates a Lockup Linear stream,
    /// otherwise it transfers the tokens directly to the recipient.
    ///
    /// @dev It emits a {Claim} event.
    ///
    /// Requirements:
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    /// - All requirements from {ISablierLockup.createWithTimestampsLL} must be met.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claim(uint256 index, address recipient, uint128 amount, bytes32[] calldata merkleProof) external payable;
}
