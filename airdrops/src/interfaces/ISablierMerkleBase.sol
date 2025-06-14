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

    /// @notice Emitted when the min USD fee is lowered by the comptroller.
    event LowerMinFeeUSD(address indexed comptroller, uint256 newMinFeeUSD, uint256 previousMinFeeUSD);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The timestamp at which campaign starts and claim begins.
    /// @dev This is an immutable state variable.
    function CAMPAIGN_START_TIME() external view returns (uint40);

    /// @notice Retrieves the address of the comptroller contract.
    function COMPTROLLER() external view returns (address);

    /// @notice The domain separator, as required by EIP-712 and EIP-1271, used for signing claim to prevent replay
    /// attacks across different campaigns.
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice The cut-off point for the campaign, as a Unix timestamp. A value of zero means there is no expiration.
    /// @dev This is an immutable state variable.
    function EXPIRATION() external view returns (uint40);

    /// @notice Returns `true` indicating that this campaign contract is deployed using the Sablier Factory.
    /// @dev This is a constant state variable.
    function IS_SABLIER_MERKLE() external view returns (bool);

    /// @notice The root of the Merkle tree used to validate the proofs of inclusion.
    /// @dev This is an immutable state variable.
    function MERKLE_ROOT() external view returns (bytes32);

    /// @notice The ERC-20 token to distribute.
    /// @dev This is an immutable state variable.
    function TOKEN() external view returns (IERC20);

    /// @notice Retrieves the name of the campaign.
    function campaignName() external view returns (string memory);

    /// @notice Retrieves the timestamp when the first claim is made, and zero if no claim was made yet.
    function firstClaimTime() external view returns (uint40);

    /// @notice Returns a flag indicating whether a claim has been made for a given index.
    /// @dev Uses a bitmap to save gas.
    /// @param index The index of the recipient to check.
    function hasClaimed(uint256 index) external view returns (bool);

    /// @notice Returns a flag indicating whether the campaign has expired.
    function hasExpired() external view returns (bool);

    /// @notice The content identifier for indexing the campaign on IPFS.
    /// @dev An empty value may break certain UI features that depend upon the IPFS CID.
    function ipfsCID() external view returns (string memory);

    /// @notice Retrieves the min USD fee required to claim the airdrop, denominated in 8 decimals.
    /// @dev The denomination is based on Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function minFeeUSD() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

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

    /// @notice Lowers the min USD fee.
    ///
    /// @dev Emits a {LowerMinFeeUSD} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller.
    /// - The new fee must be less than the current {minFeeUSD}.
    /// @param newMinFeeUSD The new min USD fee to set, denominated in 8 decimals.
    function lowerMinFeeUSD(uint256 newMinFeeUSD) external;
}
