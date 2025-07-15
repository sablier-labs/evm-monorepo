// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierMerkleLockup } from "./ISablierMerkleLockup.sol";

/// @title ISablierMerkleLL
/// @notice MerkleLL enables an airdrop model with a vesting period powered by the Lockup Linear model.
interface ISablierMerkleLL is ISablierMerkleLockup {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an airdrop is claimed using direct transfer on behalf of an eligible recipient.
    /// @param index The index of the airdrop recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens claimed using direct transfer.
    /// @param to The address receiving the claim amount on behalf of the airdrop recipient.
    /// @param viaSig Bool indicating whether the claim is made via a signature.
    event ClaimLLWithTransfer(uint256 index, address indexed recipient, uint128 amount, address to, bool viaSig);

    /// @notice Emitted when an airdrop is claimed using Lockup Linear stream on behalf of an eligible recipient.
    /// @param index The index of the airdrop recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens claimed using Lockup Linear stream.
    /// @param streamId The ID of the Lockup stream.
    /// @param to The address receiving the Lockup stream on behalf of the airdrop recipient.
    /// @param viaSig Bool indicating whether the claim is made via a signature.
    event ClaimLLWithVesting(
        uint256 index, address indexed recipient, uint128 amount, uint256 indexed streamId, address to, bool viaSig
    );

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
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
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claim airdrop on behalf of eligible recipient. If the vesting end time is in the future, it creates a
    /// Lockup Linear stream, otherwise it transfers the tokens directly to the recipient address.
    ///
    /// @dev It emits either {ClaimLLWithTransfer} or {ClaimLLWithVesting} event.
    ///
    /// Requirements:
    /// - The current time must be greater than or equal to the campaign start time.
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {COMPTROLLER.calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    /// - All requirements from {ISablierLockupLinear.createWithTimestampsLL} must be met.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claim(uint256 index, address recipient, uint128 amount, bytes32[] calldata merkleProof) external payable;

    /// @notice Claim airdrop. If the vesting end time is in the future, it creates a Lockup Linear stream with `to`
    /// address as the stream recipient, otherwise it transfers the tokens directly to the `to` address.
    ///
    /// @dev It emits either {ClaimLLWithTransfer} or {ClaimLLWithVesting} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the airdrop recipient.
    /// - The `to` must not be the zero address.
    /// - Refer to the requirements in {claim}.
    ///
    /// @param index The index of the `msg.sender` in the Merkle tree.
    /// @param to The address to which Lockup stream or ERC-20 tokens will be sent on behalf of `msg.sender`.
    /// @param amount The amount of ERC-20 tokens allocated to the `msg.sender`.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claimTo(uint256 index, address to, uint128 amount, bytes32[] calldata merkleProof) external payable;

    /// @notice Claim airdrop on behalf of eligible recipient using an EIP-712 or EIP-1271 signature. If the vesting end
    /// time is in the future, it creates a Lockup Linear stream with `to` address as the stream recipient, otherwise it
    /// transfers the tokens directly to the `to` address.
    ///
    /// @dev It emits either {ClaimLLWithTransfer} or {ClaimLLWithVesting} event.
    ///
    /// Requirements:
    /// - If `recipient` is an EOA, it must match the recovered signer.
    /// - If `recipient` is a contract, it must implement the IERC-1271 interface.
    /// - The `to` must not be the zero address.
    /// - The `validFrom` must be less than or equal to the current block timestamp.
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
    ///     { name: "validFrom", type: "uint40" },
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
    ///   amount: "1000000000000000000000", // The amount of tokens allocated to the recipient
    ///   validFrom: 1752425637 // The timestamp from which the claim signature is valid
    /// },
    /// ```
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient who is providing the signature.
    /// @param to The address to which Lockup stream or ERC-20 tokens will be sent on behalf of the recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
    /// @param validFrom The timestamp from which the claim signature is valid.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    /// @param signature The EIP-712 or EIP-1271 signature from the airdrop recipient.
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable;
}
