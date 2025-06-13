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

    function test_WhenSignerSameAsRecipient()
        external
        override
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
    {
        uint128 forgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;
        uint256 previousFeeAccrued = address(factoryMerkleVCA).balance;
        uint256 index = getIndexInMerkleTree();

        eip712Signature = generateSignature(users.recipient, address(merkleVCA));

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: index,
            recipient: users.recipient,
            claimAmount: VCA_CLAIM_AMOUNT,
            forgoneAmount: forgoneAmount,
            to: users.eve
        });

        expectCallToTransfer({ to: users.eve, value: VCA_CLAIM_AMOUNT });
        expectCallToClaimViaSigWithMsgValue(address(merkleVCA), MIN_FEE_WEI);

        claimViaSig();

        assertTrue(merkleVCA.hasClaimed(index), "not claimed");
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
        assertEq(address(factoryMerkleVCA).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }

    function test_WhenRecipientImplementsIERC1271Interface()
        external
        override
        whenToAddressNotZero
        givenRecipientIsContract
    {
        uint128 forgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;
        uint256 previousFeeAccrued = address(factoryMerkleVCA).balance;
        uint256 index = getIndexInMerkleTree(users.smartWalletWithIERC1271);

        eip712Signature = generateSignature(users.smartWalletWithIERC1271, address(merkleVCA));

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: index,
            recipient: users.smartWalletWithIERC1271,
            claimAmount: VCA_CLAIM_AMOUNT,
            forgoneAmount: forgoneAmount,
            to: users.eve
        });

        expectCallToTransfer({ to: users.eve, value: VCA_CLAIM_AMOUNT });

        claimViaSig({
            msgValue: MIN_FEE_WEI,
            index: index,
            recipient: users.smartWalletWithIERC1271,
            to: users.eve,
            amount: VCA_FULL_AMOUNT,
            merkleProof: getMerkleProof(users.smartWalletWithIERC1271),
            signature: eip712Signature
        });

        assertTrue(merkleVCA.hasClaimed(index), "not claimed");
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
        assertEq(address(factoryMerkleVCA).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }
}
