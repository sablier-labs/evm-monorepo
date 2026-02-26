// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice Struct containing vault IDs used in tests.
struct VaultIds {
    // Default vault ID (without adapter).
    uint256 defaultVault;
    // A vault ID that does not exist.
    uint256 nullVault;
    // A settled vault.
    uint256 settledVault;
    // A vault with Lido adapter enabled.
    uint256 vaultWithAdapter;
}

/// @notice Struct containing test user addresses.
struct Users {
    // Impartial user.
    address payable alice;
    // Malicious user.
    address payable eve;
    // A user who has already deposited tokens into a vault.
    address payable depositor;
    // A user who is interested in depositing tokens into a vault.
    address payable newDepositor;
}
