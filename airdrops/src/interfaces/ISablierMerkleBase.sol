// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAdminable } from "@sablier/lockup/src/interfaces/IAdminable.sol";

/// @title ISablierMerkleBase
/// @dev Common interface between Merkle Lockups and Merkle Instant.
interface ISablierMerkleBase is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin claws back the unclaimed tokens.
    event Clawback(address indexed admin, address indexed to, uint128 amount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The cut-off point for the campaign, as a Unix timestamp. A value of zero means there is no expiration.
    /// @dev This is an immutable state variable.
    function EXPIRATION() external returns (uint40);

    /// @notice Retrieves the address of the factory contract.
    function FACTORY() external view returns (address);

    /// @notice Retrieves the minimum fee required to claim the airdrop, which is paid in the native token of the chain,
    /// e.g. ETH for Ethereum Mainnet.
    function FEE() external view returns (uint256);

    /// @notice The root of the Merkle tree used to validate the proofs of inclusion.
    /// @dev This is an immutable state variable.
    function MERKLE_ROOT() external returns (bytes32);

    /// @notice The ERC-20 token to distribute.
    /// @dev This is an immutable state variable.
    function TOKEN() external returns (IERC20);

    /// @notice Retrieves the name of the campaign.
    function campaignName() external view returns (string memory);

    /// @notice Returns the timestamp when the first claim is made.
    function getFirstClaimTime() external view returns (uint40);

    /// @notice Returns a flag indicating whether a claim has been made for a given index.
    /// @dev Uses a bitmap to save gas.
    /// @param index The index of the recipient to check.
    function hasClaimed(uint256 index) external returns (bool);

    /// @notice Returns a flag indicating whether the campaign has expired.
    function hasExpired() external view returns (bool);

    /// @notice The content identifier for indexing the campaign on IPFS.
    function ipfsCID() external view returns (string memory);

    /// @notice Retrieves the shape of the lockup stream that the campaign produces upon claiming.
    function shape() external view returns (string memory);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Makes the claim.
    ///
    /// @dev Depending on the Merkle campaign, it either transfers tokens to the recipient or creates a Lockup stream
    /// with an NFT minted to the recipient.
    ///
    /// Requirements:
    /// - The campaign must not have expired.
    /// - The stream must not have been claimed already.
    /// - The Merkle proof must be valid.
    /// - The `msg.value` must not be less than `FEE`.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens to be transferred to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claim(uint256 index, address recipient, uint128 amount, bytes32[] calldata merkleProof) external payable;

    /// @notice Claws back the unclaimed tokens from the campaign.
    ///
    /// @dev Emits a {Clawback} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - No claim must be made, OR
    ///   The current timestamp must not exceed 7 days after the first claim, OR
    ///   The campaign must be expired.
    ///
    /// @param to The address to receive the tokens.
    /// @param amount The amount of tokens to claw back.
    function clawback(address to, uint128 amount) external;

    /// @notice Collects the accrued fees by transferring them to `FACTORY` admin.
    ///
    /// Requirements:
    /// - `msg.sender` must be the `FACTORY` contract.
    ///
    /// @param factoryAdmin The address of the `FACTORY` admin.
    /// @return feeAmount The amount of native tokens (e.g., ETH) collected as fees.
    function collectFees(address factoryAdmin) external returns (uint256 feeAmount);
}
