// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleExecute
/// @notice MerkleExecute enables an airdrop distribution model where eligible users claim tokens and immediately
/// execute a call on a target contract (useful for staking, lending pool deposits). This is achieved by approving the
/// target contract to spend user's tokens, followed by a call using the stored function selector combined with
/// user-provided arguments.
interface ISablierMerkleExecute is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a claim is executed on behalf of an eligible recipient.
    event ClaimExecute(uint256 index, address indexed recipient, uint128 amount, address indexed target);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The function selector to call on the target contract.
    /// @dev This is an immutable state variable.
    function SELECTOR() external view returns (bytes4);

    /// @notice The address of the target contract to call with the claim amount.
    /// @dev This is an immutable state variable.
    function TARGET() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claim airdrop and execute the call to the target contract.
    ///
    /// @dev It emits a {ClaimExecute} event.
    ///
    /// Notes:
    /// - The function approves the exact claim amount to the {TARGET}, executes the call, then revokes the approval.
    /// - The function does not forward native tokens to the target contract, so calls to targets that require a native
    /// token payment will revert.
    ///
    /// Requirements:
    /// - The current time must be greater than or equal to the campaign start time.
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {COMPTROLLER.calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    /// - `msg.sender` must be the airdrop recipient.
    /// - The external call to the target contract must succeed.
    /// - The target contract must transfer the entire claim amount from the campaign.
    ///
    /// @param index The index of `msg.sender` in the Merkle tree.
    /// @param amount The amount of ERC-20 tokens allocated to `msg.sender`.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    /// @param selectorArguments The function ABI-encoded arguments for {SELECTOR}.
    function claimAndExecute(
        uint256 index,
        uint128 amount,
        bytes32[] calldata merkleProof,
        bytes calldata selectorArguments
    )
        external
        payable;
}
