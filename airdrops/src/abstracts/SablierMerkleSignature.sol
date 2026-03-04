// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { ISablierMerkleSignature } from "./../interfaces/ISablierMerkleSignature.sol";
import { Errors } from "./../libraries/Errors.sol";
import { SignatureHash } from "./../libraries/SignatureHash.sol";
import { SablierMerkleBase } from "./SablierMerkleBase.sol";

/// @title SablierMerkleSignature
/// @notice See the documentation in {ISablierMerkleSignature}.
abstract contract SablierMerkleSignature is
    ISablierMerkleSignature, // 2 inherited components
    SablierMerkleBase // 3 inherited components
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Cache the chain ID in order to invalidate the cached domain separator if the chain ID changes in case of a
    /// chain split.
    uint256 private immutable _CACHED_CHAIN_ID;

    /// @dev The domain separator, as required by EIP-712 and EIP-1271, used for signing claim to prevent replay attacks
    /// across different campaigns.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;

    /// @dev A private variable to store the attestor address if set after the contract is deployed. If zero, the
    /// attestor is queried from the comptroller.
    address private _attestor;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Constructs the contract by initializing the immutable state variables.
    constructor() {
        // Cache the chain ID.
        _CACHED_CHAIN_ID = block.chainid;

        // Compute and store the domain separator to be used for claiming using an EIP-712 or EIP-1271 signature.
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(SignatureHash.DOMAIN_TYPEHASH, SignatureHash.PROTOCOL_NAME, block.chainid, address(this))
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleSignature
    function attestor() external view override returns (address) {
        return _getAttestor();
    }

    /// @inheritdoc ISablierMerkleSignature
    function domainSeparator() external view override returns (bytes32) {
        return _domainSeparator();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleSignature
    function setAttestor(address newAttestor) external override {
        // Check: the caller is the comptroller or the campaign admin.
        if (msg.sender != admin && msg.sender != COMPTROLLER) {
            revert Errors.SablierMerkleSignature_CallerNotAuthorized({
                caller: msg.sender,
                campaignAdmin: admin,
                comptroller: COMPTROLLER
            });
        }

        //  Get the current attestor.
        address currentAttestor = _getAttestor();

        // Effect: set the new attestor.
        _attestor = newAttestor;

        // Log the event.
        emit SetAttestor({ caller: msg.sender, previousAttestor: currentAttestor, newAttestor: newAttestor });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Verifies that the attestation signature created for the recipient is signed by the attestor. It supports
    /// both EIP-712 and EIP-1271 signatures.
    function _verifyAttestationSignature(address recipient, uint40 expireAt, bytes calldata signature) internal view {
        // Get the attestor address.
        address attestor_ = _getAttestor();

        // Check: the attestor is set.
        if (attestor_ == address(0)) {
            revert Errors.SablierMerkleSignature_AttestorNotSet();
        }

        // Check: the `expireAt` timestamp is not in the past.
        if (expireAt < block.timestamp) {
            revert Errors.SablierMerkleSignature_AttestationExpired(expireAt, block.timestamp);
        }

        // Create the struct hash for the identity.
        bytes32 identityHash = keccak256(abi.encode(SignatureHash.IDENTITY_TYPEHASH, recipient, expireAt));

        // Verify that the signature is signed by the attestor.
        _verifySignature({ signer: attestor_, structHash: identityHash, signature: signature });
    }

    /// @dev Verifies that the claim signature is signed by the recipient. It supports both EIP-712 and EIP-1271
    /// signatures.
    function _verifyClaimSignature(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom,
        bytes calldata signature
    )
        internal
        view
    {
        // Encode the parameters using claim type hash and hash it.
        bytes32 claimHash = keccak256(abi.encode(SignatureHash.CLAIM_TYPEHASH, index, recipient, to, amount, validFrom));

        // Verify that the signature is signed by the recipient.
        _verifySignature({ signer: recipient, structHash: claimHash, signature: signature });

        // Check: the `validFrom` is less than or equal to the current block timestamp.
        if (validFrom > uint40(block.timestamp)) {
            revert Errors.SablierMerkleSignature_SignatureNotYetValid(validFrom, uint40(block.timestamp));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Returns the domain separator for the current chain.
    function _domainSeparator() private view returns (bytes32) {
        // If the current chain ID is the same as the cached chain ID, return the cached domain separator.
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        }
        // Otherwise, compute the domain separator for the current chain ID.
        else {
            return keccak256(
                abi.encode(SignatureHash.DOMAIN_TYPEHASH, SignatureHash.PROTOCOL_NAME, block.chainid, address(this))
            );
        }
    }

    /// @dev Returns the attestor address.
    function _getAttestor() private view returns (address) {
        // If the attestor is stored in the contract, return it.
        if (_attestor != address(0)) {
            return _attestor;
        }

        // Otherwise, return it from the comptroller.
        return ISablierComptroller(COMPTROLLER).attestor();
    }

    /// @dev Verifies that the EIP-712 or EIP-1271 signature is signed by the expected signer.
    function _verifySignature(address signer, bytes32 structHash, bytes calldata signature) private view {
        // Create keccak256 digest of the claim parameters using claim hash and the domain separator.
        bytes32 digest =
            MessageHashUtils.toTypedDataHash({ domainSeparator: _domainSeparator(), structHash: structHash });

        // If recipient is an EOA, `isValidSignatureNow` recovers the signer using ECDSA from the signature and the
        // digest. It returns true if the recovered signer matches the recipient. If the recipient is a contract,
        // `isValidSignatureNow` checks if the recipient implements the `IERC1271` interface and returns the magic value
        // as per EIP-1271 for the given digest and signature.
        bool isSignatureValid =
            SignatureChecker.isValidSignatureNow({ signer: signer, hash: digest, signature: signature });

        // Check: `isSignatureValid` is true.
        if (!isSignatureValid) {
            revert Errors.SablierMerkleSignature_InvalidSignature();
        }
    }
}
