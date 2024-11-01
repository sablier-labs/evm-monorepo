// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

abstract contract GetFirstClaimTime_Integration_Test is MerkleCampaign_Integration_Test {
    function test_WhenFirstClaimNotMade() external view {
        // It should return 0.
        uint256 firstClaimTime = merkleBase.getFirstClaimTime();
        assertEq(firstClaimTime, 0);
    }

    function test_WhenFirstClaimMade() external {
        // Make the first claim to set `_firstClaimTime`.
        claim();

        // It should return the time of the first claim.
        uint256 firstClaimTime = merkleBase.getFirstClaimTime();
        assertEq(firstClaimTime, getBlockTimestamp());
    }
}
