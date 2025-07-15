// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { StdConstants } from "forge-std/src/StdConstants.sol";
import { SignatureHash } from "src/libraries/SignatureHash.sol";

library Utilities {
    /// @notice Computes the EIP-712 domain separator for the provided Merkle contract.
    function computeEIP712DomainSeparator(address merkleContract) internal view returns (bytes32) {
        return keccak256(
            abi.encode(SignatureHash.DOMAIN_TYPEHASH, SignatureHash.PROTOCOL_NAME, block.chainid, merkleContract)
        );
    }

    /// @notice Generates the EIP-191 signature for the given claim parameters and returns it.
    function generateEIP191Signature(
        uint256 signerPrivateKey,
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom
    )
        internal
        pure
        returns (bytes memory signature)
    {
        // Compute the claim hash.
        bytes32 claimHash = keccak256(abi.encodePacked(index, recipient, to, amount, validFrom));

        // Compute the keccak256 digest of the claim hash.
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(claimHash);

        // Return the signature.
        signature = sign(signerPrivateKey, digest);
    }

    /// @notice Generates the EIP-712 signature for the given claim parameters and returns it.
    function generateEIP712Signature(
        uint256 signerPrivateKey,
        address merkleContract,
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom
    )
        internal
        view
        returns (bytes memory signature)
    {
        // Compute the domain separator.
        bytes32 domainSeparator = computeEIP712DomainSeparator(merkleContract);

        // Compute the claim hash.
        bytes32 claimHash = keccak256(abi.encode(SignatureHash.CLAIM_TYPEHASH, index, recipient, to, amount, validFrom));

        // Compute the keccak256 digest of the EIP-712 typed data.
        bytes32 digest = MessageHashUtils.toTypedDataHash({ domainSeparator: domainSeparator, structHash: claimHash });

        // Return the signature.
        signature = sign(signerPrivateKey, digest);
    }

    /// @notice Signs the provided digest using private key and returns the signature.
    function sign(uint256 signerPrivateKey, bytes32 digest) internal pure returns (bytes memory signature) {
        // Sign the digest.
        (uint8 v, bytes32 r, bytes32 s) = StdConstants.VM.sign(signerPrivateKey, digest);

        // Return the signature.
        signature = abi.encodePacked(r, s, v);
    }
}
