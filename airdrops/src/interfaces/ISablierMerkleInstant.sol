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

    /// @notice Claim airdrop on behalf of eligible recipient and transfer it to the recipient address.
    ///
    /// @dev It emits a {Claim} event.
    ///
    /// Requirements:
    /// - The current time must be greater than or equal to the campaign start time.
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {COMPTROLLER.calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claim(uint256 index, address recipient, uint128 amount, bytes32[] calldata merkleProof) external payable;

    /// @notice Claim airdrop and transfer the tokens to the `to` address.
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

    /// @notice Claim airdrop on behalf of eligible recipient using an EIP-712 or EIP-1271 signature, and transfer the
    /// tokens to the `to` address.
    ///
    /// @dev It emits a {Claim} event.
    ///
    /// Requirements:
    /// - If `recipient` is an EOA, it must match the recovered signer.
    /// - If `recipient` is a contract, it must implement the IERC-1271 interface.
    /// - The `to` is not the zero address.
    /// - Refer to the requirements in {claim}.
    ///
    /// Below is the example of typed data to be signed by the airdrop recipient, referenced from
    /// https://docs.metamask.io/wallet/how-to/sign-data/#example.
    ///
    /// ```json
    /// types: {
    ///   EIP712Domain: [
    ///     { name: "name", type: "string" },
    ///     { name: "chainId", type: "uint256" },
    ///     { name: "verifyingContract", type: "address" },
    ///   ],
    ///   Claim: [
    ///     { name: "index", type: "uint256" },
    ///     { name: "recipient", type: "address" },
    ///     { name: "to", type: "address" },
    ///     { name: "amount", type: "uint128" },
    ///   ],
    /// },
    /// domain: {
    ///   name: "Sablier Airdrops Protocol",
    ///   chainId: 1, // Chain on which the contract is deployed
    ///   verifyingContract: "0xTheAddressOfThisContract", // The address of this contract
    /// },
    /// primaryType: "Claim",
    /// message: {
    ///   index: 2, // The index of the signer in the Merkle tree
    ///   recipient: "0xTheAddressOfTheRecipient", // The address of the airdrop recipient
    ///   to: "0xTheAddressReceivingTheTokens", // The address where recipient wants to transfer the tokens
    ///   amount: "1000000000000000000000" // The amount of tokens allocated to the recipient
    /// },
    /// ```
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient who is providing the signature.
    /// @param to The address receiving the ERC-20 tokens on behalf of the recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    /// @param signature The EIP-712 or EIP-1271 signature from the airdrop recipient.
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable;
}
