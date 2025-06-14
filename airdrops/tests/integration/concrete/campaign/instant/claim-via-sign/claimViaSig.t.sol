// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { ClaimViaSig_Integration_Test } from "./../../shared/claim-via-sig/claimViaSig.t.sol";
import { MerkleInstant_Integration_Shared_Test } from "./../MerkleInstant.t.sol";

contract ClaimViaSig_MerkleInstant_Integration_Test is
    ClaimViaSig_Integration_Test,
    MerkleInstant_Integration_Shared_Test
{
    function setUp() public virtual override(MerkleInstant_Integration_Shared_Test, ClaimViaSig_Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
        ClaimViaSig_Integration_Test.setUp();
    }

    function test_WhenSignerSameAsRecipient()
        external
        override
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        eip712Signature = generateSignature(users.recipient, address(merkleInstant));

        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.Claim(index, users.recipient, CLAIM_AMOUNT, users.eve);

        expectCallToTransfer({ to: users.eve, value: CLAIM_AMOUNT });
        expectCallToClaimViaSigWithMsgValue(address(merkleInstant), AIRDROP_MIN_FEE_WEI);
        claimViaSig();

        assertTrue(merkleInstant.hasClaimed(index), "not claimed");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }

    function test_WhenRecipientImplementsIERC1271Interface()
        external
        override
        whenToAddressNotZero
        givenRecipientIsContract
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree(users.smartWalletWithIERC1271);

        eip712Signature = generateSignature(users.smartWalletWithIERC1271, address(merkleInstant));

        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.Claim(index, users.smartWalletWithIERC1271, CLAIM_AMOUNT, users.eve);

        expectCallToTransfer({ to: users.eve, value: CLAIM_AMOUNT });
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: index,
            recipient: users.smartWalletWithIERC1271,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(users.smartWalletWithIERC1271),
            signature: eip712Signature
        });

        assertTrue(merkleInstant.hasClaimed(index), "not claimed");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
