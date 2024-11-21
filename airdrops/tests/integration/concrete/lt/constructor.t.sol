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
        bool actualCancelable;
        uint40 actualExpiration;
        address actualFactory;
        string actualIpfsCID;
        address actualLockup;
        bytes32 actualMerkleRoot;
        string actualName;
        uint256 actualFee;
        uint40 actualStreamStartTime;
        address actualToken;
        uint64 actualTotalPercentage;
        MerkleLT.TrancheWithPercentage[] actualTranchesWithPercentages;
        bool actualTransferable;
        address expectedAdmin;
        uint256 expectedAllowance;
        bool expectedCancelable;
        uint40 expectedExpiration;
        address expectedFactory;
        string expectedIpfsCID;
        address expectedLockup;
        bytes32 expectedMerkleRoot;
        bytes32 expectedName;
        uint256 expectedFee;
        uint40 expectedStreamStartTime;
        address expectedToken;
        uint64 expectedTotalPercentage;
        MerkleLT.TrancheWithPercentage[] expectedTranchesWithPercentages;
        bool expectedTransferable;
    }

    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactory));

        SablierMerkleLT constructedLT = new SablierMerkleLT(
            defaults.baseParams(),
            lockup,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            defaults.STREAM_START_TIME_ZERO(),
            defaults.tranchesWithPercentages(),
            defaults.DEFAULT_FEE()
        );

        Vars memory vars;

        vars.actualAdmin = constructedLT.admin();
        vars.expectedAdmin = users.campaignOwner;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualAllowance = dai.allowance(address(constructedLT), address(lockup));
        vars.expectedAllowance = MAX_UINT256;
        assertEq(vars.actualAllowance, vars.expectedAllowance, "allowance");

        vars.actualToken = address(constructedLT.TOKEN());
        vars.expectedToken = address(dai);
        assertEq(vars.actualToken, vars.expectedToken, "token");

        vars.actualCancelable = constructedLT.CANCELABLE();
        vars.expectedCancelable = defaults.CANCELABLE();
        assertEq(vars.actualCancelable, vars.expectedCancelable, "cancelable");

        vars.actualExpiration = constructedLT.EXPIRATION();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualFactory = constructedLT.FACTORY();
        vars.expectedFactory = address(merkleFactory);
        assertEq(vars.actualFactory, vars.expectedFactory, "factory");

        vars.actualIpfsCID = constructedLT.ipfsCID();
        vars.expectedIpfsCID = defaults.IPFS_CID();
        assertEq(vars.actualIpfsCID, vars.expectedIpfsCID, "ipfsCID");

        vars.actualLockup = address(constructedLT.LOCKUP());
        vars.expectedLockup = address(lockup);
        assertEq(vars.actualLockup, vars.expectedLockup, "lockup");

        vars.actualMerkleRoot = constructedLT.MERKLE_ROOT();
        vars.expectedMerkleRoot = defaults.MERKLE_ROOT();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        vars.actualName = constructedLT.name();
        vars.expectedName = defaults.NAME_BYTES32();
        assertEq(bytes32(abi.encodePacked(vars.actualName)), vars.expectedName, "name");

        vars.actualFee = constructedLT.FEE();
        vars.expectedFee = defaults.DEFAULT_FEE();
        assertEq(vars.actualFee, vars.expectedFee, "fee");

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
    }
}
