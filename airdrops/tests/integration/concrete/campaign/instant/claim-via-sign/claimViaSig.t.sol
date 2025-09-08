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

    function test_WhenSignatureValidityTimestampNotInFuture()
        external
        override
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
        whenSignerSameAsRecipient
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        eip712Signature = generateSignature(users.recipient, address(merkleInstant));

        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.ClaimInstant(index, users.recipient, CLAIM_AMOUNT, users.eve, true);

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
        emit ISablierMerkleInstant.ClaimInstant(index, users.smartWalletWithIERC1271, CLAIM_AMOUNT, users.eve, true);

        expectCallToTransfer({ to: users.eve, value: CLAIM_AMOUNT });
        claimViaSig(users.smartWalletWithIERC1271, CLAIM_AMOUNT);

        assertTrue(merkleInstant.hasClaimed(index), "not claimed");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
