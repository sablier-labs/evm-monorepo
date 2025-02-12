// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_MerkleLT_Integration_Test is Integration_Test {
    /// @dev Needed to prevent "Stack too deep" error
    struct Vars {
        address actualAdmin;
        uint256 actualAllowance;
        string actualCampaignName;
        uint40 actualExpiration;
        address actualFactory;
        string actualIpfsCID;
        address actualLockup;
        bytes32 actualMerkleRoot;
        uint256 actualFee;
        bool actualStreamCancelable;
        uint40 actualStreamStartTime;
        bool actualStreamTransferable;
        address actualToken;
        uint64 actualTotalPercentage;
        MerkleLT.TrancheWithPercentage[] actualTranchesWithPercentages;
        address expectedAdmin;
        uint256 expectedAllowance;
        string expectedCampaignName;
        uint40 expectedExpiration;
        address expectedFactory;
        string expectedIpfsCID;
        address expectedLockup;
        bytes32 expectedMerkleRoot;
        uint256 expectedFee;
        bool expectedStreamCancelable;
        uint40 expectedStreamStartTime;
        bool expectedStreamTransferable;
        address expectedToken;
        uint64 expectedTotalPercentage;
        MerkleLT.TrancheWithPercentage[] expectedTranchesWithPercentages;
    }

    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactory));

        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        SablierMerkleLT constructedLT = new SablierMerkleLT(params, users.campaignOwner);

        Vars memory vars;

        vars.actualAdmin = constructedLT.admin();
        vars.expectedAdmin = users.campaignOwner;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualAllowance = dai.allowance(address(constructedLT), address(lockup));
        vars.expectedAllowance = MAX_UINT256;
        assertEq(vars.actualAllowance, vars.expectedAllowance, "allowance");

        vars.actualCampaignName = constructedLT.campaignName();
        vars.expectedCampaignName = defaults.CAMPAIGN_NAME();
        assertEq(vars.actualCampaignName, vars.expectedCampaignName, "campaign name");

        vars.actualExpiration = constructedLT.EXPIRATION();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualFactory = constructedLT.FACTORY();
        vars.expectedFactory = address(merkleFactory);
        assertEq(vars.actualFactory, vars.expectedFactory, "factory");

        vars.actualFee = constructedLT.FEE();
        vars.expectedFee = defaults.FEE();
        assertEq(vars.actualFee, vars.expectedFee, "fee");

        vars.actualIpfsCID = constructedLT.ipfsCID();
        vars.expectedIpfsCID = defaults.IPFS_CID();
        assertEq(vars.actualIpfsCID, vars.expectedIpfsCID, "ipfsCID");

        vars.actualLockup = address(constructedLT.LOCKUP());
        vars.expectedLockup = address(lockup);
        assertEq(vars.actualLockup, vars.expectedLockup, "lockup");

        vars.actualMerkleRoot = constructedLT.MERKLE_ROOT();
        vars.expectedMerkleRoot = defaults.MERKLE_ROOT();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        assertEq(constructedLT.shape(), defaults.SHAPE(), "shape");

        vars.actualStreamCancelable = constructedLT.STREAM_CANCELABLE();
        vars.expectedStreamCancelable = defaults.CANCELABLE();
        assertEq(vars.actualStreamCancelable, vars.expectedStreamCancelable, "stream cancelable");

        vars.actualStreamStartTime = constructedLT.STREAM_START_TIME();
        vars.expectedStreamStartTime = defaults.STREAM_START_TIME_ZERO();
        assertEq(vars.actualStreamStartTime, vars.expectedStreamStartTime, "stream start time");

        vars.actualStreamTransferable = constructedLT.STREAM_TRANSFERABLE();
        vars.expectedStreamTransferable = defaults.TRANSFERABLE();
        assertEq(vars.actualStreamTransferable, vars.expectedStreamTransferable, "stream transferable");

        vars.actualToken = address(constructedLT.TOKEN());
        vars.expectedToken = address(dai);
        assertEq(vars.actualToken, vars.expectedToken, "token");

        vars.actualTotalPercentage = constructedLT.TOTAL_PERCENTAGE();
        vars.expectedTotalPercentage = defaults.TOTAL_PERCENTAGE();
        assertEq(vars.actualTotalPercentage, vars.expectedTotalPercentage, "totalPercentage");

        vars.actualTranchesWithPercentages = constructedLT.getTranchesWithPercentages();
        vars.expectedTranchesWithPercentages = params.tranchesWithPercentages;
        assertEq(vars.actualTranchesWithPercentages, vars.expectedTranchesWithPercentages);
    }
}
