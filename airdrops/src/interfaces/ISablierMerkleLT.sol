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
    function TRANCHES_TOTAL_PERCENTAGE() external view returns (uint64);

    /// @notice Retrieves the start time of the vesting stream, as a Unix timestamp. Zero is a sentinel value for
    /// `block.timestamp`.
    function VESTING_START_TIME() external returns (uint40);

    /// @notice Retrieves the tranches with their respective unlock percentages and durations.
    function tranchesWithPercentages() external view returns (MerkleLT.TrancheWithPercentage[] memory);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Makes the claim. If the vesting end time is in the future, it creates a Lockup Tranched stream,
    /// otherwise it transfers the tokens directly to the recipient.
    ///
    /// @dev It emits a {Claim} event.
    ///
    /// Requirements:
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    /// - The sum of percentages of the tranches must equal 100%.
    /// - All requirements from {ISablierLockup.createWithTimestampsLT} must be met.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claim(uint256 index, address recipient, uint128 amount, bytes32[] calldata merkleProof) external payable;
}
