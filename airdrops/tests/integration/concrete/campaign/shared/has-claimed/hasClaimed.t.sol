// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract HasClaimed_Integration_Test is Integration_Test {
    function test_WhenIndexNotInMerkleTree() external view {
        uint256 indexNotInTree = 1337e18;
        assertFalse(merkleBase.hasClaimed(indexNotInTree), "claimed");
    }

    function test_GivenRecipientNotClaimed() external view whenIndexInMerkleTree {
        // It should return false.
        assertFalse(merkleBase.hasClaimed(getIndexInMerkleTree()), "claimed");
    }

    function test_GivenRecipientClaimed() external whenIndexInMerkleTree {
        // Make the first claim to set `firstClaimTime`.
        claim();

        // It should return true.
        assertTrue(merkleBase.hasClaimed(getIndexInMerkleTree()), "not claimed");
    }
}
