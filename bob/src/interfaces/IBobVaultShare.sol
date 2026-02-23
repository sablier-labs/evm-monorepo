// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title IBobVaultShare
/// @notice Interface for the ERC-20 token representing shares in a Bob vault.
interface IBobVaultShare is IERC20Metadata {
    /*//////////////////////////////////////////////////////////////////////////
                               USER-FACING CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the Bob contract with the authority to mint and burn tokens.
    function SABLIER_BOB() external view returns (address);

    /// @notice Returns the vault ID this share token represents.
    function VAULT_ID() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Mints `amount` tokens to `to`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    /// - The caller must be the SablierBob contract.
    /// - `vaultId` must be equal to the {VAULT_ID}.
    ///
    /// @param vaultId The vault ID that this share token represents.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(uint256 vaultId, address to, uint256 amount) external;

    /// @notice Burns `amount` tokens from `from`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    /// - The caller must be the SablierBob contract.
    /// - `vaultId` must be equal to the {VAULT_ID}.
    /// - `from` must have at least `amount` tokens.
    ///
    /// @param vaultId The vault ID that this share token represents.
    /// @param from The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 vaultId, address from, uint256 amount) external;
}
