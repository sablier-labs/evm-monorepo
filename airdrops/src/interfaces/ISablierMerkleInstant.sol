// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleInstant
/// @notice MerkleInstant enables an airdrop model where eligible users receive the tokens as soon as they claim.
interface ISablierMerkleInstant is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when `to` receives the airdrop through a direct transfer on behalf of `recipient`.
    event Claim(uint256 index, address indexed recipient, uint128 amount, address to);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Makes the claim by transferring the tokens directly to the recipient.
    ///
    /// @dev It emits a {Claim} event.
    ///
    /// Requirements:
    /// - The current time must be greater than or equal to the campaign start time.
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claim(uint256 index, address recipient, uint128 amount, bytes32[] calldata merkleProof) external payable;

    /// @notice Makes the claim by transferring the tokens directly to the `to` address.
    ///
    /// @dev It emits a {Claim} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the airdrop recipient.
    /// - The `to` must not be the zero address.
    /// - Refer to the requirements in {claim}.
    ///
    /// @param index The index of the `msg.sender` in the Merkle tree.
    /// @param to The address receiving the ERC-20 tokens on behalf of `msg.sender`.
    /// @param amount The amount of ERC-20 tokens allocated to the `msg.sender`.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claimTo(uint256 index, address to, uint128 amount, bytes32[] calldata merkleProof) external payable;
}
