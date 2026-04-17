// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { ClaimType } from "src/types/MerkleBase.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ClaimViaSig_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        // Make `users.campaignCreator` the caller for this test.
        setMsgSender(users.campaignCreator);
    }

    function test_RevertGiven_NotDefaultClaimType() external {
        merkleBase = merkleBaseAttest;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_UnsupportedClaimType.selector, ClaimType.DEFAULT, ClaimType.ATTEST
            )
        );
        claimViaSig();
    }

    function test_RevertWhen_ToAddressZero() external givenDefaultClaimType {
        vm.expectRevert(Errors.SablierMerkleBase_ToZeroAddress.selector);
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            to: address(0),
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM,
            merkleProof: getMerkleProof(),
            signature: abi.encode(0)
        });
    }

    function test_RevertWhen_SignatureNotCompatible()
        external
        givenDefaultClaimType
        whenToAddressNotZero
        givenRecipientIsEOA
    {
        uint256 index = getIndexInMerkleTree();

        // Generate an incompatible signature.
        bytes memory incompatibleSignature = vm.randomBytes(65);

        // Expect revert.
        vm.expectRevert(Errors.SablierMerkleSignature_InvalidSignature.selector);
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: index,
            recipient: users.recipient,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM,
            merkleProof: getMerkleProof(),
            signature: incompatibleSignature
        });
    }

    function test_RevertWhen_SignerDifferentFromRecipient()
        external
        givenDefaultClaimType
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
    {
        uint256 index = getIndexInMerkleTree();

        // Create a new user.
        (address newSigner, uint256 newSignerPrivateKey) = makeAddrAndKey("new signer");

        setMsgSender(newSigner);

        // Generate the signature using the new user's private key.
        bytes memory signatureFromNewSigner = generateEIP712Signature({
            signerPrivateKey: newSignerPrivateKey,
            merkleContract: address(merkleBase),
            index: index,
            recipient: users.recipient,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM
        });

        // Expect revert.
        vm.expectRevert(Errors.SablierMerkleSignature_InvalidSignature.selector);
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: index,
            recipient: users.recipient,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM,
            merkleProof: getMerkleProof(),
            signature: signatureFromNewSigner
        });
    }

    function test_RevertWhen_SignatureValidityTimestampInFuture()
        external
        givenDefaultClaimType
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
        whenSignerSameAsRecipient
    {
        uint256 index = getIndexInMerkleTree();

        // Warp to a timestamp before the `VALID_FROM` so that the signature is not valid.
        vm.warp(VALID_FROM - 1);

        // Generate the signature using the new user's private key.
        bytes memory signatureFromNewSigner = generateEIP712Signature({
            signerPrivateKey: recipientPrivateKey,
            merkleContract: address(merkleBase),
            index: index,
            recipient: users.recipient,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM
        });

        // Expect revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleSignature_SignatureNotYetValid.selector, VALID_FROM, VALID_FROM - 1
            )
        );
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: index,
            recipient: users.recipient,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM,
            merkleProof: getMerkleProof(),
            signature: signatureFromNewSigner
        });
    }

    /// @dev Since the implementation of `claimViaSig()` differs in each Merkle campaign, we declare this virtual dummy
    /// test. The child contracts implement it.
    function test_WhenSignatureValidityTimestampNotInFuture()
        external
        virtual
        givenDefaultClaimType
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
        whenSignerSameAsRecipient
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the comptroller.
    }

    function test_RevertWhen_RecipientNotImplementIERC1271Interface()
        external
        givenDefaultClaimType
        whenToAddressNotZero
        givenRecipientIsContract
    {
        vm.expectRevert(Errors.SablierMerkleSignature_InvalidSignature.selector);
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(users.smartWalletWithoutIERC1271),
            recipient: users.smartWalletWithoutIERC1271,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM,
            merkleProof: getMerkleProof(users.smartWalletWithoutIERC1271),
            signature: abi.encode(0)
        });
    }

    /// @dev Since the implementation of `claimViaSig()` differs in each Merkle campaign, we declare this virtual dummy
    /// test. The child contracts implement it.
    function test_WhenRecipientImplementsIERC1271Interface()
        external
        virtual
        givenDefaultClaimType
        whenToAddressNotZero
        givenRecipientIsContract
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the comptroller.
    }
}
