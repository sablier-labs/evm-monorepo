// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAdminable } from "@sablier/evm-utils/src/interfaces/IAdminable.sol";

/// @title ISablierMerkleBase
/// @dev Common interface between campaign contracts.
interface ISablierMerkleBase is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin claws back the unclaimed tokens.
    event Clawback(address indexed admin, address indexed to, uint128 amount);

    /// @notice Emitted when the min USD fee is lowered by the admin.
    event LowerMinFeeUSD(address indexed factoryAdmin, uint256 newMinFeeUSD, uint256 previousMinFeeUSD);

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

    /// @notice Calculates the min fee in wei required to claim the airdrop.
    /// @dev Uses {minFeeUSD} and the oracle price.
    ///
    /// The price is considered to be 0 if:
    /// 1. The oracle is not set.
    /// 2. The min USD fee is 0.
    /// 3. The oracle price is ≤ 0.
    /// 4. The oracle's update timestamp is in the future.
    /// 5. The oracle price hasn't been updated in the last 24 hours.
    ///
    /// @return The min fee in wei, denominated in 18 decimals (1e18 = 1 native token).
    function calculateMinFeeWei() external view returns (uint256);

    /// @notice Retrieves the name of the campaign.
    function campaignName() external view returns (string memory);

    /// @notice Retrieves the timestamp when the first claim is made, and zero if no claim was made yet.
    function firstClaimTime() external view returns (uint40);

    /// @notice Returns a flag indicating whether a claim has been made for a given index.
    /// @dev Uses a bitmap to save gas.
    /// @param index The index of the recipient to check.
    function hasClaimed(uint256 index) external returns (bool);

    /// @notice Returns a flag indicating whether the campaign has expired.
    function hasExpired() external view returns (bool);

    /// @notice The content identifier for indexing the campaign on IPFS.
    function ipfsCID() external view returns (string memory);

    /// @notice Retrieves the min USD fee required to claim the airdrop, denominated in 8 decimals.
    /// @dev The denomination is based on Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function minFeeUSD() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Makes the claim.
    ///
    /// @dev Emits a {Claim} event.
    ///
    /// Notes:
    /// - For Merkle Instant and Merkle VCA campaigns, it transfers the tokens directly to the recipient.
    /// - For Merkle Lockup campaigns, it creates a Lockup stream only if the end time is still in the future. Otherwise,
    /// it transfers the tokens directly to the recipient.
    ///
    /// Requirements:
    /// - The campaign must not have expired.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    /// - `msg.value` must not be less than the value returned by {calculateMinFeeWei}.
    ///
    /// @param index The index of the recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient.
    /// @param amount The amount of ERC-20 tokens allocated to the recipient.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    function claim(uint256 index, address recipient, uint128 amount, bytes32[] calldata merkleProof) external payable;

    /// @notice Claws back the unclaimed tokens.
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

    /// @notice Collects the accrued fees by transferring them to {FACTORY}.
    ///
    /// Requirements:
    /// - `msg.sender` must be {FACTORY}.
    ///
    /// @param factoryAdmin The address of the admin of {FACTORY}.
    /// @return feeAmount The amount of native tokens (e.g., ETH) collected as fees.
    function collectFees(address factoryAdmin) external returns (uint256 feeAmount);

    /// @notice Lowers the min USD fee.
    ///
    /// @dev Emits a {LowerMinFeeUSD} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin of {FACTORY}.
    /// - The new fee must be less than the current {minFeeUSD}.
    /// @param newMinFeeUSD The new min USD fee to set, denominated in 8 decimals.
    function lowerMinFeeUSD(uint256 newMinFeeUSD) external;
}
