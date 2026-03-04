// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierMerkleSignature } from "./ISablierMerkleSignature.sol";

/// @title ISablierMerkleVCA
/// @notice VCA stands for Variable Claim Amount, and is an airdrop model where the claim amount increases linearly
/// until the airdrop period ends. Claiming early results in forgoing the remaining amount, whereas claiming after the
/// period grants the full amount that was allocated.
interface ISablierMerkleVCA is ISablierMerkleSignature {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an airdrop is claimed on behalf of an eligible recipient.
    event ClaimVCA(
        uint256 index,
        address indexed recipient,
        uint128 claimAmount,
        uint128 forgoneAmount,
        address to,
        bool viaSig
    );

    /// @notice Emitted when the redistribution is enabled.
    event RedistributionEnabled();

    /// @notice Emitted when a recipient receives rewards from the forgone tokens pool.
    event RedistributionReward(uint256 index, address indexed recipient, uint128 amount, address to);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the total amount of ERC-20 tokens allocated to the campaign.
    function AGGREGATE_AMOUNT() external view returns (uint128);

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
    /// @dev This is for informational purposes only. Reverts if the claim time is less than the vesting start
    /// time, since the claim cannot be made, no amount can be forgone.
    /// @param fullAmount The amount of tokens allocated to a user, denominated in the token's decimals.
    /// @param claimTime A hypothetical time at which to make the claim. Zero is a sentinel value for `block.timestamp`.
    /// @return The amount that would be forgone, denominated in the token's decimals.
    function calculateForgoneAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128);

    /// @notice Calculates the redistribution rewards for a given full amount.
    /// @dev Notes:
    /// - Reverts if redistribution is not enabled.
    /// - If `AGGREGATE_AMOUNT` is set lower than actual total allocations in the Merkle tree, this might return 0
    /// rather than reverting.
    /// @param fullAmount The amount of tokens that the redistribution rewards are to be calculated for.
    function calculateRedistributionRewards(uint128 fullAmount) external view returns (uint128);

    /// @notice Retrieves a bool indicating whether the redistribution of forgone tokens is enabled or not.
    function isRedistributionEnabled() external view returns (bool);

    /// @notice Retrieves the total amount of tokens forgone by early claimers.
    function totalForgoneAmount() external view returns (uint128);

    /// @notice Retrieves the total amount of redistribution rewards paid out.
    function totalRedistributionAmountPaid() external view returns (uint128);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claim airdrop. If the vesting end time is in the future, it calculates the claim amount to transfer to
    /// the `to` address, otherwise it transfers the full amount. If the redistribution is enabled, it calculates the
    /// reward amount based on the total amount of tokens forgone by early claimers and transfers it to the recipients
    /// claiming after the vesting end time.
    ///
    /// @dev It emits a {ClaimVCA} event, and a {RedistributionReward} event if the redistribution is enabled.
    ///
    /// Notes:
    /// - There can be a race condition among recipients if:
    ///   1. `AGGREGATE_AMOUNT` is set lower than the actual total allocations in the Merkle tree.
    ///   2. The campaign is not sufficiently funded with the actual total allocations.
    /// - The rewards are transferred to the recipients at the time of claiming. If the campaign creator turns the
    /// redistribution on after the vesting end time, the recipients who have already claimed the full amount would miss
    /// on the rewards while subsequent recipients would get them.
    ///
    /// Requirements:
    /// - `CLAIM_TYPE` must be `DEFAULT`.
    /// - The current time must be greater than or equal to the campaign start time.
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {COMPTROLLER.calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    /// - The claim amount must be greater than zero.
    /// - `msg.sender` must be the airdrop recipient.
    /// - The `to` must not be the zero address.
    ///
    /// @param index The index of the `msg.sender` in the Merkle tree.
    /// @param to The address receiving the ERC-20 tokens on behalf of `msg.sender`.
    /// @param fullAmount The total amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claimTo(uint256 index, address to, uint128 fullAmount, bytes32[] calldata merkleProof) external payable;

    /// @notice Claim airdrop using an external attestation from a trusted attestor (e.g., KYC verifier). If the vesting
    /// end time is in the future, it calculates the claim amount to transfer to the `to` address, otherwise it
    /// transfers the full amount.
    ///
    /// @dev It emits a {ClaimVCA} event.
    ///
    /// Notes:
    /// - The attestation must be an EIP-712 signature from the attestor.
    /// - See the example in the {claimViaSig} function.
    /// - If the attestor is not set in the campaign, the attestor from the comptroller is used.
    ///
    /// Requirements:
    /// - `msg.sender` must be the airdrop recipient.
    /// - `CLAIM_TYPE` must be `ATTEST`.
    /// - The `to` must not be the zero address.
    /// - The attestor must not be the zero address.
    /// - The `expireAt` timestamp must not be in the past.
    /// - The attestation signature must be valid.
    /// - Refer to the requirements in {claimTo}.
    ///
    /// @param index The index of the `msg.sender` in the Merkle tree.
    /// @param to The address receiving the ERC-20 tokens on behalf of `msg.sender`.
    /// @param fullAmount The total amount of ERC-20 tokens allocated to the `msg.sender`.
    /// @param expireAt The timestamp after which the attestation signature is no longer valid.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    /// @param attestation The EIP-712 signature from the attestor.
    function claimViaAttestation(
        uint256 index,
        address to,
        uint128 fullAmount,
        uint40 expireAt,
        bytes32[] calldata merkleProof,
        bytes calldata attestation
    )
        external
        payable;

    /// @notice Claim airdrop on behalf of eligible recipient using an EIP-712 or EIP-1271 signature. If the vesting end
    /// time is in the future, it calculates the claim amount to transfer to the `to` address, otherwise it transfers
    /// the full amount.
    ///
    /// @dev It emits a {ClaimVCA} event.
    ///
    /// Requirements:
    /// - `CLAIM_TYPE` must be `DEFAULT`.
    /// - If `recipient` is an EOA, it must match the recovered signer.
    /// - If `recipient` is a contract, it must implement the IERC-1271 interface.
    /// - The `to` must not be the zero address.
    /// - The `validFrom` must be less than or equal to the current block timestamp.
    /// - Refer to the requirements in {claimTo} except that there are no restrictions on `msg.sender`.
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
    /// @param to The address receiving the ERC-20 tokens on behalf of the recipient.
    /// @param fullAmount The total amount of ERC-20 tokens allocated to the recipient.
    /// @param validFrom The timestamp from which the claim signature is valid.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    /// @param signature The EIP-712 or EIP-1271 signature from the airdrop recipient.
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 fullAmount,
        uint40 validFrom,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable;

    /// @notice Enable the redistribution of forgone tokens among recipients claiming after the vesting end time,
    /// proportional to their allocation amount. Once enabled, it cannot be disabled.
    ///
    /// @dev Notes:
    /// - It is recommended to fund the campaign with the actual total allocation in the Merkle tree (ideally equivalent
    /// to `AGGREGATE_AMOUNT`) to avoid race conditions among the recipients.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - `VESTING_END_TIME` must be in the future.
    /// - Redistribution must not be already enabled.
    function enableRedistribution() external;
}
