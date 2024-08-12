// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleCampaign_Integration_Shared_Test } from "../../shared/MerkleCampaign.t.sol";

abstract contract HasClaimed_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Shared_Test.setUp();
    }

    function test_HasClaimed_IndexNotInTree() external {
        uint256 indexNotInTree = 1337e18;
        assertFalse(merkleBase.hasClaimed(indexNotInTree), "claimed");
    }

    function test_HasClaimed_NotClaimed() external whenIndexInTree {
        assertFalse(merkleBase.hasClaimed(defaults.INDEX1()), "claimed");
    }

    function test_HasClaimed() external whenIndexInTree givenRecipientHasClaimed {
        assertTrue(merkleBase.hasClaimed(defaults.INDEX1()), "not claimed");
    }
}
