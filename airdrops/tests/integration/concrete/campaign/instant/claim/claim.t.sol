// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { Claim_Integration_Test } from "./../../shared/claim/claim.t.sol";
import { MerkleInstant_Integration_Shared_Test, Integration_Test } from "./../MerkleInstant.t.sol";

contract Claim_MerkleInstant_Integration_Test is Claim_Integration_Test, MerkleInstant_Integration_Shared_Test {
    function setUp() public virtual override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
    }

    function test_WhenMerkleProofValid()
        external
        override
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.ClaimInstant(index, users.recipient, CLAIM_AMOUNT, users.recipient, false);

        expectCallToTransfer({ to: users.recipient, value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleInstant), AIRDROP_MIN_FEE_WEI);
        claim();

        assertTrue(merkleInstant.hasClaimed(index), "not claimed");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
