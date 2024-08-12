// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleCampaign_Integration_Shared_Test } from "../../shared/MerkleCampaign.t.sol";

abstract contract GetFirstClaimTime_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Shared_Test.setUp();
    }

    function test_GetFirstClaimTime_BeforeFirstClaim() external view {
        uint256 firstClaimTime = merkleBase.getFirstClaimTime();
        assertEq(firstClaimTime, 0);
    }

    function test_GetFirstClaimTime() external view afterFirstClaim {
        uint256 firstClaimTime = merkleBase.getFirstClaimTime();
        assertEq(firstClaimTime, getBlockTimestamp());
    }
}
