// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";

import { ClaimViaSig_Integration_Test } from "./../../shared/claim-via-sig/claimViaSig.t.sol";
import { MerkleVCA_Integration_Shared_Test } from "./../MerkleVCA.t.sol";

contract ClaimViaSig_MerkleVCA_Integration_Test is ClaimViaSig_Integration_Test, MerkleVCA_Integration_Shared_Test {
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, ClaimViaSig_Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
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
        uint128 forgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        eip712Signature = generateSignature(users.recipient, address(merkleVCA));

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.ClaimVCA({
            index: index,
            recipient: users.recipient,
            claimAmount: VCA_CLAIM_AMOUNT,
            forgoneAmount: forgoneAmount,
            to: users.eve,
            viaSig: true
        });

        expectCallToTransfer({ to: users.eve, value: VCA_CLAIM_AMOUNT });
        expectCallToClaimViaSigWithMsgValue(address(merkleVCA), AIRDROP_MIN_FEE_WEI);

        claimViaSig();

        assertTrue(merkleVCA.hasClaimed(index), "not claimed");
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }

    function test_WhenRecipientImplementsIERC1271Interface()
        external
        override
        whenToAddressNotZero
        givenRecipientIsContract
    {
        uint128 forgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree(users.smartWalletWithIERC1271);

        eip712Signature = generateSignature(users.smartWalletWithIERC1271, address(merkleVCA));

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.ClaimVCA({
            index: index,
            recipient: users.smartWalletWithIERC1271,
            claimAmount: VCA_CLAIM_AMOUNT,
            forgoneAmount: forgoneAmount,
            to: users.eve,
            viaSig: true
        });

        expectCallToTransfer({ to: users.eve, value: VCA_CLAIM_AMOUNT });

        claimViaSig(users.smartWalletWithIERC1271, VCA_FULL_AMOUNT);

        assertTrue(merkleVCA.hasClaimed(index), "not claimed");
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
