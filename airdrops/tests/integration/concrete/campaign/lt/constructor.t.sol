// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

contract Constructor_MerkleLT_Integration_Test is Integration_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        setMsgSender(address(factoryMerkleLT));

        // Deploy the SablierMerkleLT contract.
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        SablierMerkleLT constructedLT = new SablierMerkleLT(params, users.campaignCreator);

        // Token allowance
        uint256 actualAllowance = dai.allowance(address(constructedLT), address(lockup));
        assertEq(actualAllowance, MAX_UINT256, "allowance");

        // SablierMerkleBase
        assertEq(constructedLT.admin(), users.campaignCreator, "admin");
        assertEq(constructedLT.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedLT.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(address(constructedLT.FACTORY()), address(factoryMerkleLT), "factory");
        assertEq(constructedLT.ipfsCID(), IPFS_CID, "IPFS CID");
        assertEq(constructedLT.MERKLE_ROOT(), MERKLE_ROOT, "Merkle root");
        assertEq(constructedLT.minFeeUSD(), MIN_FEE_USD, "min fee USD");
        assertEq(constructedLT.ORACLE(), address(oracle), "oracle");
        assertEq(address(constructedLT.TOKEN()), address(dai), "token");

        // SablierMerkleLockup
        assertEq(address(constructedLT.SABLIER_LOCKUP()), address(lockup), "Sablier Lockup");
        assertEq(constructedLT.streamShape(), STREAM_SHAPE, "stream shape");
        assertEq(constructedLT.STREAM_CANCELABLE(), STREAM_CANCELABLE, "stream cancelable");
        assertEq(constructedLT.STREAM_TRANSFERABLE(), STREAM_TRANSFERABLE, "stream transferable");

        // SablierMerkleLT
        assertEq(constructedLT.TOTAL_PERCENTAGE(), TOTAL_PERCENTAGE, "totalPercentage");
        assertEq(constructedLT.VESTING_START_TIME(), VESTING_START_TIME, "vesting start time");
        assertEq(constructedLT.getTranchesWithPercentages(), params.tranchesWithPercentages);
    }
}
