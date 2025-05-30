// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLL } from "src/SablierMerkleLL.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

contract Constructor_MerkleLL_Integration_Test is Integration_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        setMsgSender(address(factoryMerkleLL));

        // Deploy the SablierMerkleLL contract.
        SablierMerkleLL constructedLL = new SablierMerkleLL(merkleLLConstructorParams(), users.campaignCreator);

        // Token allowance
        uint256 actualAllowance = dai.allowance(address(constructedLL), address(lockup));
        assertEq(actualAllowance, MAX_UINT256, "allowance");

        // SablierMerkleBase
        assertEq(constructedLL.admin(), users.campaignCreator, "admin");
        assertEq(constructedLL.CAMPAIGN_START_TIME(), CAMPAIGN_START_TIME, "campaign start time");
        assertEq(constructedLL.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedLL.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(address(constructedLL.FACTORY()), address(factoryMerkleLL), "factory");
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
        assertEq(constructedLL.VESTING_CLIFF_DURATION(), VESTING_CLIFF_DURATION, "vesting cliff duration");
        assertEq(
            constructedLL.VESTING_CLIFF_UNLOCK_PERCENTAGE(),
            VESTING_CLIFF_UNLOCK_PERCENTAGE,
            "vesting cliff unlock percentage"
        );
        assertEq(constructedLL.VESTING_START_TIME(), VESTING_START_TIME, "vesting start time");
        assertEq(
            constructedLL.VESTING_START_UNLOCK_PERCENTAGE(),
            VESTING_START_UNLOCK_PERCENTAGE,
            "vesting start unlock percentage"
        );
        assertEq(constructedLL.VESTING_TOTAL_DURATION(), VESTING_TOTAL_DURATION, "vesting total duration");
    }
}
