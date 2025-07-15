// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Utilities } from "tests/utils/Utilities.sol";
import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ClaimViaSig_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        // Make `users.campaignCreator` the caller for this test.
        setMsgSender(users.campaignCreator);
    }

    function test_RevertWhen_ToAddressZero() external {
        vm.expectRevert(Errors.SablierMerkleBase_ToZeroAddress.selector);
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            to: address(0),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            signature: abi.encode(0)
        });
    }

    function test_RevertWhen_SignatureNotCompatible() external whenToAddressNotZero givenRecipientIsEOA {
        uint256 index = getIndexInMerkleTree();

        // Generate an incompatible signature.
        bytes memory incompatibleSignature =
            Utilities.generateEIP191Signature(recipientPrivateKey, index, users.eve, users.recipient, CLAIM_AMOUNT);

        // Expect revert.
        vm.expectRevert(Errors.SablierMerkleBase_InvalidSignature.selector);
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: index,
            recipient: users.recipient,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            signature: incompatibleSignature
        });
    }

    function test_RevertWhen_SignerDifferentFromRecipient()
        external
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
    {
        uint256 index = getIndexInMerkleTree();

        // Create a new user.
        (address newSigner, uint256 newSignerPrivateKey) = makeAddrAndKey("new signer");

        setMsgSender(newSigner);

        // Generate the signature using the new user's private key.
        bytes memory signatureFromNewSigner = Utilities.generateEIP712Signature(
            newSignerPrivateKey, address(merkleBase), index, users.recipient, users.eve, CLAIM_AMOUNT
        );

        // Expect revert.
        vm.expectRevert(Errors.SablierMerkleBase_InvalidSignature.selector);
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: index,
            recipient: users.recipient,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            signature: signatureFromNewSigner
        });
    }

    /// @dev Since the implementation of `claimViaSig()` differs in each Merkle campaign, we declare this virtual dummy
    /// test. The child contracts implement it.
    function test_WhenSignerSameAsRecipient()
        external
        virtual
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the merkle lockup.
    }

    function test_RevertWhen_RecipientNotImplementIERC1271Interface()
        external
        whenToAddressNotZero
        givenRecipientIsContract
    {
        vm.expectRevert(Errors.SablierMerkleBase_InvalidSignature.selector);
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(users.smartWalletWithoutIERC1271),
            recipient: users.smartWalletWithoutIERC1271,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(users.smartWalletWithoutIERC1271),
            signature: abi.encode(0)
        });
    }

    /// @dev Since the implementation of `claimViaSig()` differs in each Merkle campaign, we declare this virtual dummy
    /// test. The child contracts implement it.
    function test_WhenRecipientImplementsIERC1271Interface()
        external
        virtual
        whenToAddressNotZero
        givenRecipientIsContract
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the merkle lockup.
    }
}
