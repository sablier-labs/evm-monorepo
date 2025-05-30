// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { Claim_Integration_Test } from "./../../shared/claim/claim.t.sol";
import { MerkleInstant_Integration_Shared_Test, Integration_Test } from "./../MerkleInstant.t.sol";

contract Claim_MerkleInstant_Integration_Test is Claim_Integration_Test, MerkleInstant_Integration_Shared_Test {
    function setUp() public virtual override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
    }

    function test_Claim()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
        whenMerkleProofValid
    {
        uint256 previousFeeAccrued = address(merkleInstant).balance;

        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.Claim(INDEX1, users.recipient1, CLAIM_AMOUNT, users.recipient1);

        expectCallToTransfer({ to: users.recipient1, value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleInstant), MIN_FEE_WEI);
        claim();

        assertTrue(merkleInstant.hasClaimed(INDEX1), "not claimed");

        assertEq(address(merkleInstant).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }
}
