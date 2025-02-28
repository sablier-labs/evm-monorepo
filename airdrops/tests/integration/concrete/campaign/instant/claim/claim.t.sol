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
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientValid
        whenAmountValid
        whenMerkleProofValid
    {
        uint256 previousFeeAccrued = address(merkleInstant).balance;

        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.Claim(INDEX1, users.recipient1, CLAIM_AMOUNT);

        expectCallToTransfer({ to: users.recipient1, value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleInstant), MINIMUM_FEE_IN_WEI);
        claim();

        assertTrue(merkleInstant.hasClaimed(INDEX1), "not claimed");

        assertEq(address(merkleInstant).balance, previousFeeAccrued + MINIMUM_FEE_IN_WEI, "fee collected");
    }
}
