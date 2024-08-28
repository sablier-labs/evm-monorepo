// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLT } from "src/periphery/SablierMerkleLT.sol";
import { MerkleLT } from "src/periphery/types/DataTypes.sol";

import { MerkleCampaign_Integration_Test } from "../MerkleCampaign.t.sol";

contract Constructor_MerkleLT_Integration_Test is MerkleCampaign_Integration_Test {
    /// @dev Needed to prevent "Stack too deep" error
    struct Vars {
        address actualAdmin;
        uint256 actualAllowance;
        address actualAsset;
        string actualIpfsCID;
        string actualName;
        bool actualCancelable;
        uint40 actualExpiration;
        address actualLockupTranched;
        bytes32 actualMerkleRoot;
        uint40 actualStreamStartTime;
        uint64 actualTotalPercentage;
        MerkleLT.TrancheWithPercentage[] actualTranchesWithPercentages;
        bool actualTransferable;
        address expectedAdmin;
        uint256 expectedAllowance;
        address expectedAsset;
        bool expectedCancelable;
        string expectedIpfsCID;
        uint40 expectedExpiration;
        address expectedLockupTranched;
        bytes32 expectedMerkleRoot;
        bytes32 expectedName;
        uint40 expectedStreamStartTime;
        uint64 expectedTotalPercentage;
        MerkleLT.TrancheWithPercentage[] expectedTranchesWithPercentages;
        bool expectedTransferable;
    }

    function test_Constructor() external {
        SablierMerkleLT constructedLT = new SablierMerkleLT(
            defaults.baseParams(),
            lockupTranched,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            defaults.STREAM_START_TIME_ZERO(),
            defaults.tranchesWithPercentages()
        );

        Vars memory vars;

        vars.actualAsset = address(constructedLT.ASSET());
        vars.expectedAsset = address(dai);
        assertEq(vars.actualAsset, vars.expectedAsset, "asset");

        vars.actualExpiration = constructedLT.EXPIRATION();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualAdmin = constructedLT.admin();
        vars.expectedAdmin = users.admin;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualIpfsCID = constructedLT.ipfsCID();
        vars.expectedIpfsCID = defaults.IPFS_CID();
        assertEq(vars.actualIpfsCID, vars.expectedIpfsCID, "ipfsCID");

        vars.actualMerkleRoot = constructedLT.MERKLE_ROOT();
        vars.expectedMerkleRoot = defaults.MERKLE_ROOT();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        vars.actualName = constructedLT.name();
        vars.expectedName = defaults.NAME_BYTES32();
        assertEq(bytes32(abi.encodePacked(vars.actualName)), vars.expectedName, "name");

        vars.actualCancelable = constructedLT.CANCELABLE();
        vars.expectedCancelable = defaults.CANCELABLE();
        assertEq(vars.actualCancelable, vars.expectedCancelable, "cancelable");

        vars.actualLockupTranched = address(constructedLT.LOCKUP_TRANCHED());
        vars.expectedLockupTranched = address(lockupTranched);
        assertEq(vars.actualLockupTranched, vars.expectedLockupTranched, "lockupTranched");

        vars.actualStreamStartTime = constructedLT.STREAM_START_TIME();
        vars.expectedStreamStartTime = defaults.STREAM_START_TIME_ZERO();
        assertEq(vars.actualStreamStartTime, vars.expectedStreamStartTime, "streamStartTime");

        vars.actualTotalPercentage = constructedLT.TOTAL_PERCENTAGE();
        vars.expectedTotalPercentage = defaults.TOTAL_PERCENTAGE();
        assertEq(vars.actualTotalPercentage, vars.expectedTotalPercentage, "totalPercentage");

        vars.actualTransferable = constructedLT.TRANSFERABLE();
        vars.expectedTransferable = defaults.TRANSFERABLE();
        assertEq(vars.actualTransferable, vars.expectedTransferable, "transferable");

        vars.actualTranchesWithPercentages = constructedLT.getTranchesWithPercentages();
        vars.expectedTranchesWithPercentages = defaults.tranchesWithPercentages();
        assertEq(vars.actualTranchesWithPercentages, vars.expectedTranchesWithPercentages, "tranchesWithPercentages");

        vars.actualAllowance = dai.allowance(address(constructedLT), address(lockupTranched));
        vars.expectedAllowance = MAX_UINT256;
        assertEq(vars.actualAllowance, vars.expectedAllowance, "allowance");
    }
}
