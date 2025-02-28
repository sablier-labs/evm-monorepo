// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

contract Constructor_MerkleLT_Integration_Test is Integration_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactoryLT));

        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        SablierMerkleLT constructedLT = new SablierMerkleLT(params, users.campaignOwner);

        uint256 actualAllowance = dai.allowance(address(constructedLT), address(lockup));
        assertEq(actualAllowance, MAX_UINT256, "allowance");

        assertEq(constructedLT.admin(), users.campaignOwner, "admin");
        assertEq(constructedLT.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedLT.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(address(constructedLT.FACTORY()), address(merkleFactoryLT), "factory");
        assertEq(constructedLT.ipfsCID(), IPFS_CID, "ipfsCID");
        assertEq(address(constructedLT.LOCKUP()), address(lockup), "lockup");
        assertEq(constructedLT.MERKLE_ROOT(), MERKLE_ROOT, "merkleRoot");
        assertEq(constructedLT.minimumFee(), MINIMUM_FEE, "minimum fee");
        assertEq(constructedLT.shape(), SHAPE, "shape");
        assertEq(constructedLT.STREAM_CANCELABLE(), CANCELABLE, "stream cancelable");
        assertEq(constructedLT.STREAM_START_TIME(), ZERO, "stream start time");
        assertEq(constructedLT.STREAM_TRANSFERABLE(), TRANSFERABLE, "stream transferable");
        assertEq(address(constructedLT.TOKEN()), address(dai), "token");
        assertEq(constructedLT.TOTAL_PERCENTAGE(), TOTAL_PERCENTAGE, "totalPercentage");
        assertEq(constructedLT.getTranchesWithPercentages(), params.tranchesWithPercentages);
    }
}
