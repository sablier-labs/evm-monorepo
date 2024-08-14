// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleInstant_Integration_Shared_Test } from "../MerkleInstant.t.sol";
import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";

contract Claim_MerkleInstant_Integration_Test is Claim_Integration_Test, MerkleInstant_Integration_Shared_Test {
    function setUp() public override(Claim_Integration_Test, MerkleInstant_Integration_Shared_Test) {
        super.setUp();
    }

    function test_ClaimInstant() external givenCampaignNotExpired givenNotClaimed givenIncludedInMerkleTree {
        vm.expectEmit({ emitter: address(merkleBase) });
        emit Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT());

        expectCallToTransfer({ to: users.recipient1, value: defaults.CLAIM_AMOUNT() });
        claim();

        assertTrue(merkleBase.hasClaimed(defaults.INDEX1()), "not claimed");
    }
}
