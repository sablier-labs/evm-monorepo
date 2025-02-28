// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAdminable } from "@sablier/evm-utils/src/interfaces/IAdminable.sol";

/// @title ISablierMerkleBase
/// @dev Common interface between Merkle campaigns.
interface ISablierMerkleBase is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin claws back the unclaimed tokens.
    event Clawback(address indexed admin, address indexed to, uint128 amount);

    /// @notice Emitted when the minimum fee is reduced.
    event LowerMinimumFee(address indexed factoryAdmin, uint256 newFee, uint256 previousFee);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The cut-off point for the campaign, as a Unix timestamp. A value of zero means there is no expiration.
    /// @dev This is an immutable state variable.
    function EXPIRATION() external returns (uint40);

    /// @notice Retrieves the address of the factory contract.
    function FACTORY() external view returns (address);

    /// @notice The root of the Merkle tree used to validate the proofs of inclusion.
    /// @dev This is an immutable state variable.
    function MERKLE_ROOT() external returns (bytes32);

    /// @notice Retrieves the oracle contract address.
    /// @dev This is an immutable state variable.
    function ORACLE() external view returns (address);

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

    /// @notice Retrieves the minimum fee, in USD (8 decimals), required to claim the airdrop, to be paid in the native
    /// token of the chain.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function minimumFee() external view returns (uint256);

    /// @notice Calculates the minimum fee in wei required to claim the airdrop.
    /// @dev It uses the `minimumFee` and the oracle price to calculate the fee in wei.
    /// @return The minimum fee required to claim the airdrop, as an 18-decimal number, where 1e18 is 1 native token.
    function minimumFeeInWei() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Makes the claim.
    ///
    /// @dev Emits a {Claim} event.
    ///
    /// Notes:
    /// - For Merkle Instant and Merkle VCA campaigns, it transfers the tokens directly to the recipient.
    /// - For Merkle Lockup campaigns, it creates a Lockup stream only if vesting end time is in the future. Otherwise,
    /// it transfers the tokens directly to the recipient.
    ///
    /// Requirements:
    /// - The campaign must not have expired.
    /// - The airdrop must not have been claimed already.
    /// - The Merkle proof must be valid.
    /// - The `msg.value` must not be less than `minimumFee`.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
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

    /// @notice Sets the minimum fee to a new value lower than the current fee.
    ///
    /// @dev Emits a {LowerMinimumFee} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the `FACTORY` admin.
    /// - The new fee must be less than the current `minimumFee`.
    function lowerMinimumFee(uint256 newFee) external;
}
