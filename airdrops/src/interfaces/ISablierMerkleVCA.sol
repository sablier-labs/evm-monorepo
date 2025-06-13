// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleVCA
/// @notice VCA stands for Variable Claim Amount, and is an airdrop model where the claim amount increases linearly
/// until the airdrop period ends. Claiming early results in forgoing the remaining amount, whereas claiming after the
/// period grants the full amount that was allocated.
interface ISablierMerkleVCA is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when `to` receives the airdrop through a direct transfer on behalf of `recipient`.
    event Claim(uint256 index, address indexed recipient, uint128 claimAmount, uint128 forgoneAmount, address to);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the percentage of the full amount that will unlock immediately at the start time. The
    /// value is denominated as a fixed-point number where 1e18 is 100%.
    function UNLOCK_PERCENTAGE() external view returns (UD60x18);

    /// @notice Retrieves the time when the VCA airdrop is fully vested, as a Unix timestamp.
    function VESTING_END_TIME() external view returns (uint40);

    /// @notice Retrieves the time when the VCA airdrop begins to unlock, as a Unix timestamp.
    function VESTING_START_TIME() external view returns (uint40);

    /// @notice Calculates the amount that would be claimed if the claim were made at `claimTime`.
    /// @dev This is for informational purposes only. To actually claim the airdrop, a Merkle proof is required.
    /// @param fullAmount The amount of tokens allocated to a user, denominated in the token's decimals.
    /// @param claimTime A hypothetical time at which to make the claim. Zero is a sentinel value for `block.timestamp`.
    /// @return The amount that would be claimed, denominated in the token's decimals.
    function calculateClaimAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128);

    /// @notice Calculates the amount that would be forgone if the claim were made at `claimTime`.
    /// @dev This is for informational purposes only. Returns zero if the claim time is less than the vesting start
    /// time, since the claim cannot be made, no amount can be forgone.
    /// @param fullAmount The amount of tokens allocated to a user, denominated in the token's decimals.
    /// @param claimTime A hypothetical time at which to make the claim. Zero is a sentinel value for `block.timestamp`.
    /// @return The amount that would be forgone, denominated in the token's decimals.
    function calculateForgoneAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128);

    /// @notice Retrieves the total amount of tokens forgone by early claimers.
    function totalForgoneAmount() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claim airdrop on behalf of eligible recipient and transfer it to the recipient address. If the vesting
    /// end time is in the future, it calculates the claim amount, otherwise it transfers the full amount.
    ///
    /// @dev It emits a {Claim} event.
    ///
    /// Requirements:
    /// - The current time must be greater than or equal to the campaign start time.
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    /// - The claim amount must be greater than zero.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param fullAmount The total amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claim(
        uint256 index,
        address recipient,
        uint128 fullAmount,
        bytes32[] calldata merkleProof
    )
        external
        payable;

    /// @notice Claim airdrop. If the vesting end time is in the future, it calculates the claim amount to transfer to
    /// the `to` address, otherwise it transfers the full amount.
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
    /// @param fullAmount The total amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claimTo(uint256 index, address to, uint128 fullAmount, bytes32[] calldata merkleProof) external payable;

    /// @notice Claim airdrop on behalf of eligible recipient using an EIP-712 or EIP-1271 signature. If the vesting end
    /// time is in the future, it calculates the claim amount to transfer to the `to` address, otherwise it transfers
    /// the full amount.
    ///
    /// @dev It emits a {Claim} event.
    ///
    /// Requirements:
    /// - If `recipient` is an EOA, it must match the recovered signer.
    /// - If `recipient` is a contract, it must implement the IERC-1271 interface.
    /// - The `to` must not be the zero address.
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
    /// @param fullAmount The total amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    /// @param signature The EIP-712 or EIP-1271 signature from the airdrop recipient.
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 fullAmount,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable;
}
