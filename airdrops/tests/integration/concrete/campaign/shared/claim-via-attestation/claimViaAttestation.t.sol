// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Noop } from "@sablier/evm-utils/src/mocks/Noop.sol";

import { ISablierMerkleSignature } from "src/interfaces/ISablierMerkleSignature.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ClaimType } from "src/types/MerkleBase.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ClaimViaAttestation_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        // Make `users.recipient` the caller for this test since `claimViaAttestation` uses `msg.sender` as the
        // recipient.
        setMsgSender(users.recipient);
    }

    function test_RevertGiven_NotAttestClaimType() external {
        // Point merkleBaseAttest to the default campaign so that `claimViaAttestation` is called on the default
        // campaign.
        merkleBaseAttest = merkleBase;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_UnsupportedClaimType.selector, ClaimType.ATTEST, ClaimType.DEFAULT
            )
        );
        claimViaAttestation();
    }

    function test_RevertWhen_ToAddressZero() external givenAttestClaimType {
        // It should revert.
        vm.expectRevert(Errors.SablierMerkleBase_ToZeroAddress.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: address(0),
            amount: CLAIM_AMOUNT,
            expireAt: EXPIRATION,
            merkleProof: getMerkleProof(),
            attestation: generateAttestation()
        });
    }

    function test_RevertGiven_AttestorZero() external givenAttestClaimType whenToAddressNotZero {
        // Set the default attestor to the zero address.
        setMsgSender(admin);
        comptroller.setAttestor(address(0));

        // Change caller back to the recipient.
        setMsgSender(users.recipient);

        // It should revert.
        vm.expectRevert(Errors.SablierMerkleSignature_AttestorNotSet.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.eve,
            amount: CLAIM_AMOUNT,
            expireAt: EXPIRATION,
            merkleProof: getMerkleProof(),
            attestation: generateAttestation()
        });
    }

    function test_RevertWhen_AttestationExpired()
        external
        givenAttestClaimType
        whenToAddressNotZero
        givenAttestorNotZero
    {
        vm.warp(EXPIRATION + 1);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleSignature_AttestationExpired.selector, EXPIRATION, EXPIRATION + 1
            )
        );
        claimViaAttestation();
    }

    function test_RevertWhen_AttestationInvalid()
        external
        givenAttestClaimType
        whenToAddressNotZero
        givenAttestorNotZero
        whenAttestationNotExpired
        givenAttestorIsEOA
    {
        // Change caller to eve and use the default attestation generated for the recipient.
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(Errors.SablierMerkleSignature_InvalidSignature.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.eve,
            amount: CLAIM_AMOUNT,
            expireAt: EXPIRATION,
            merkleProof: getMerkleProof(),
            attestation: generateAttestation()
        });
    }

    /// @dev Since the implementation of `claimViaAttestation()` differs in each Merkle campaign, we declare this
    /// virtual dummy test. The child contracts implement it.
    function test_WhenAttestationValid()
        external
        virtual
        givenAttestClaimType
        whenToAddressNotZero
        givenAttestorNotZero
        whenAttestationNotExpired
        givenAttestorIsEOA
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the comptroller.
    }

    function test_RevertWhen_AttestorNotImplementIERC1271Interface()
        external
        givenAttestClaimType
        whenToAddressNotZero
        givenAttestorNotZero
        whenAttestationNotExpired
        givenAttestorIsContract
    {
        // Deploy a contract that does not implement IERC1271.
        address smartAttestorWithoutIERC1271 = address(new Noop());

        // Set the attestor to the contract without IERC1271.
        setMsgSender(users.campaignCreator);
        ISablierMerkleSignature(address(merkleBaseAttest)).setAttestor(smartAttestorWithoutIERC1271);

        // Change caller back to the recipient.
        setMsgSender(users.recipient);

        vm.expectRevert(Errors.SablierMerkleSignature_InvalidSignature.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.eve,
            amount: CLAIM_AMOUNT,
            expireAt: EXPIRATION,
            merkleProof: getMerkleProof(),
            attestation: generateAttestation()
        });
    }

    /// @dev Since the implementation of `claimViaAttestation()` differs in each Merkle campaign, we declare this
    /// virtual dummy test. The child contracts implement it.
    function test_WhenAttestorImplementsIERC1271Interface()
        external
        virtual
        givenAttestClaimType
        whenToAddressNotZero
        givenAttestorNotZero
        whenAttestationNotExpired
        givenAttestorIsContract
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the comptroller.
    }
}
