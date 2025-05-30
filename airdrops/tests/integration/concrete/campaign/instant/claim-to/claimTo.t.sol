// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { ClaimTo_Integration_Test } from "./../../shared/claim-to/claimTo.t.sol";
import { MerkleInstant_Integration_Shared_Test } from "./../MerkleInstant.t.sol";

contract ClaimTo_MerkleInstant_Integration_Test is ClaimTo_Integration_Test, MerkleInstant_Integration_Shared_Test {
    function setUp() public virtual override(MerkleInstant_Integration_Shared_Test, ClaimTo_Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
        ClaimTo_Integration_Test.setUp();
    }

    function test_ClaimTo()
        external
        whenToAddressNotZero
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenCallerNotClaimed
        whenIndexValid
        whenCallerEligible
        whenAmountValid
        whenMerkleProofValid
    {
        uint256 previousFeeAccrued = address(merkleInstant).balance;

        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.Claim(INDEX1, users.recipient1, CLAIM_AMOUNT, users.eve);

        expectCallToTransfer({ to: users.eve, value: CLAIM_AMOUNT });
        expectCallToClaimToWithMsgValue(address(merkleInstant), MIN_FEE_WEI);
        claimTo();

        assertTrue(merkleInstant.hasClaimed(INDEX1), "not claimed");

        assertEq(address(merkleInstant).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }
}
