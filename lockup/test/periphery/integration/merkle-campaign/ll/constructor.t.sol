// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLL } from "src/periphery/SablierMerkleLL.sol";
import { MerkleLL } from "src/periphery/types/DataTypes.sol";

import { MerkleCampaign_Integration_Test } from "../MerkleCampaign.t.sol";

contract Constructor_MerkleLL_Integration_Test is MerkleCampaign_Integration_Test {
    /// @dev Needed to prevent "Stack too deep" error
    struct Vars {
        address actualAdmin;
        uint256 actualAllowance;
        address actualAsset;
        string actualIpfsCID;
        string actualName;
        bool actualCancelable;
        MerkleLL.Schedule actualSchedule;
        uint40 actualExpiration;
        address actualLockupLinear;
        bytes32 actualMerkleRoot;
        bool actualTransferable;
        address expectedAdmin;
        uint256 expectedAllowance;
        address expectedAsset;
        bool expectedCancelable;
        MerkleLL.Schedule expectedSchedule;
        uint40 expectedExpiration;
        string expectedIpfsCID;
        address expectedLockupLinear;
        bytes32 expectedMerkleRoot;
        bytes32 expectedName;
        bool expectedTransferable;
    }

    function test_Constructor() external {
        SablierMerkleLL constructedLL = new SablierMerkleLL(
            defaults.baseParams(), lockupLinear, defaults.CANCELABLE(), defaults.TRANSFERABLE(), defaults.schedule()
        );

        Vars memory vars;

        vars.actualAdmin = constructedLL.admin();
        vars.expectedAdmin = users.admin;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualAllowance = dai.allowance(address(constructedLL), address(lockupLinear));
        vars.expectedAllowance = MAX_UINT256;
        assertEq(vars.actualAllowance, vars.expectedAllowance, "allowance");

        vars.actualAsset = address(constructedLL.ASSET());
        vars.expectedAsset = address(dai);
        assertEq(vars.actualAsset, vars.expectedAsset, "asset");

        vars.actualCancelable = constructedLL.CANCELABLE();
        vars.expectedCancelable = defaults.CANCELABLE();
        assertEq(vars.actualCancelable, vars.expectedCancelable, "cancelable");

        vars.actualExpiration = constructedLL.EXPIRATION();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualIpfsCID = constructedLL.ipfsCID();
        vars.expectedIpfsCID = defaults.IPFS_CID();
        assertEq(vars.actualIpfsCID, vars.expectedIpfsCID, "ipfsCID");

        vars.actualLockupLinear = address(constructedLL.LOCKUP_LINEAR());
        vars.expectedLockupLinear = address(lockupLinear);
        assertEq(vars.actualLockupLinear, vars.expectedLockupLinear, "lockupLinear");

        vars.actualMerkleRoot = constructedLL.MERKLE_ROOT();
        vars.expectedMerkleRoot = defaults.MERKLE_ROOT();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        vars.actualName = constructedLL.name();
        vars.expectedName = defaults.NAME_BYTES32();
        assertEq(bytes32(abi.encodePacked(vars.actualName)), vars.expectedName, "name");

        (vars.actualSchedule.startTime, vars.actualSchedule.cliffDuration, vars.actualSchedule.totalDuration) =
            constructedLL.schedule();
        vars.expectedSchedule = defaults.schedule();
        assertEq(vars.actualSchedule.startTime, vars.expectedSchedule.startTime, "schedule.startTime");
        assertEq(vars.actualSchedule.cliffDuration, vars.expectedSchedule.cliffDuration, "schedule.cliffDuration");
        assertEq(vars.actualSchedule.totalDuration, vars.expectedSchedule.totalDuration, "schedule.totalDuration");

        vars.actualTransferable = constructedLL.TRANSFERABLE();
        vars.expectedTransferable = defaults.TRANSFERABLE();
        assertEq(vars.actualTransferable, vars.expectedTransferable, "transferable");
    }
}
