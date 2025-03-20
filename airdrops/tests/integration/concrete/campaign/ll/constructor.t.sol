// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLL } from "src/SablierMerkleLL.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

contract Constructor_MerkleLL_Integration_Test is Integration_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(factoryMerkleLL));

        // Deploy the SablierMerkleLL contract.
        SablierMerkleLL constructedLL = new SablierMerkleLL(merkleLLConstructorParams(), users.campaignCreator);

        // Token allowance
        uint256 actualAllowance = dai.allowance(address(constructedLL), address(lockup));
        assertEq(actualAllowance, MAX_UINT256, "allowance");

        // SablierMerkleBase
        assertEq(constructedLL.admin(), users.campaignCreator, "admin");
        assertEq(constructedLL.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedLL.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(constructedLL.FACTORY(), address(factoryMerkleLL), "factory");
        assertEq(constructedLL.ipfsCID(), IPFS_CID, "IPFS CID");
        assertEq(constructedLL.MERKLE_ROOT(), MERKLE_ROOT, "merkleRoot");
        assertEq(constructedLL.minFeeUSD(), MIN_FEE_USD, "min fee USD");
        assertEq(constructedLL.ORACLE(), address(oracle), "oracle");
        assertEq(address(constructedLL.TOKEN()), address(dai), "token");

        // SablierMerkleLockup
        assertEq(address(constructedLL.SABLIER_LOCKUP()), address(lockup), "Sablier Lockup");
        assertEq(constructedLL.streamShape(), STREAM_SHAPE, "stream shape");
        assertEq(constructedLL.STREAM_CANCELABLE(), STREAM_CANCELABLE, "stream cancelable");
        assertEq(constructedLL.STREAM_TRANSFERABLE(), STREAM_TRANSFERABLE, "stream transferable");

        // SablierMerkleLL
        MerkleLL.Schedule memory actualSchedule = constructedLL.getSchedule();
        assertEq(actualSchedule.startTime, RANGED_STREAM_START_TIME, "schedule.startTime");
        assertEq(actualSchedule.startPercentage, START_PERCENTAGE, "schedule.startPercentage");
        assertEq(actualSchedule.cliffDuration, CLIFF_DURATION, "schedule.cliffDuration");
        assertEq(actualSchedule.cliffPercentage, CLIFF_PERCENTAGE, "schedule.cliffPercentage");
        assertEq(actualSchedule.totalDuration, TOTAL_DURATION, "schedule.totalDuration");
    }
}
