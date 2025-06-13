// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";

import { ClaimViaSig_Integration_Test } from "./../../shared/claim-via-sig/claimViaSig.t.sol";
import { MerkleLL_Integration_Shared_Test } from "./../MerkleLL.t.sol";

contract ClaimViaSig_MerkleLL_Integration_Test is ClaimViaSig_Integration_Test, MerkleLL_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLL_Integration_Shared_Test, ClaimViaSig_Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
        ClaimViaSig_Integration_Test.setUp();
    }

    function test_WhenSignerSameAsRecipient()
        external
        override
        whenToAddressNotZero
        givenRecipientIsEOA
        whenSignatureCompatible
    {
        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(factoryMerkleLL).balance;
        uint256 index = getIndexInMerkleTree();

        eip712Signature = generateSignature(users.recipient, address(merkleLL));

        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLockup.Claim(index, users.recipient, CLAIM_AMOUNT, expectedStreamId, users.eve);

        expectCallToTransferFrom({ from: address(merkleLL), to: address(lockup), value: CLAIM_AMOUNT });
        expectCallToClaimViaSigWithMsgValue(address(merkleLL), MIN_FEE_WEI);

        // Claim the airstream.
        claimViaSig();

        assertTrue(merkleLL.hasClaimed(index), "not claimed");

        assertEq(address(factoryMerkleLL).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }

    function test_WhenRecipientImplementsIERC1271Interface()
        external
        override
        whenToAddressNotZero
        givenRecipientIsContract
    {
        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(factoryMerkleLL).balance;
        uint256 index = getIndexInMerkleTree(users.smartWalletWithIERC1271);

        eip712Signature = generateSignature(users.smartWalletWithIERC1271, address(merkleLL));

        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLockup.Claim(index, users.smartWalletWithIERC1271, CLAIM_AMOUNT, expectedStreamId, users.eve);

        expectCallToTransferFrom({ from: address(merkleLL), to: address(lockup), value: CLAIM_AMOUNT });

        // Claim the airstream.
        claimViaSig({
            msgValue: MIN_FEE_WEI,
            index: index,
            recipient: users.smartWalletWithIERC1271,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(users.smartWalletWithIERC1271),
            signature: eip712Signature
        });

        assertTrue(merkleLL.hasClaimed(index), "not claimed");

        assertEq(address(factoryMerkleLL).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }
}
