// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title SignatureHash
/// @notice Library containing the hashes for the EIP-712 and EIP-1271 signatures.
library SignatureHash {
    /// @dev The struct type hash for computing the domain separator for EIP-712 and EIP-1271 signatures.
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(uint256 index,address recipient,address to,uint128 amount)");

    /// @notice The domain type hash for computing the domain separator.
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The protocol name for the EIP-712 and EIP-1271 signatures.
    bytes32 public constant PROTOCOL_NAME = keccak256("Sablier Airdrops Protocol");
}
