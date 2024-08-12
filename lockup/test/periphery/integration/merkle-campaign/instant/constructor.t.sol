// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleInstant } from "src/periphery/SablierMerkleInstant.sol";

import { MerkleCampaign_Integration_Test } from "../MerkleCampaign.t.sol";

contract Constructor_MerkleInstant_Integration_Test is MerkleCampaign_Integration_Test {
    /// @dev Needed to prevent "Stack too deep" error
    struct Vars {
        address actualAdmin;
        address actualAsset;
        string actualIpfsCID;
        string actualName;
        uint40 actualExpiration;
        bytes32 actualMerkleRoot;
        address expectedAdmin;
        address expectedAsset;
        uint40 expectedExpiration;
        string expectedIpfsCID;
        bytes32 expectedMerkleRoot;
        bytes32 expectedName;
    }

    function test_Constructor() external {
        SablierMerkleInstant constructedInstant = new SablierMerkleInstant(defaults.baseParams());

        Vars memory vars;

        vars.actualAdmin = constructedInstant.admin();
        vars.expectedAdmin = users.admin;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualAsset = address(constructedInstant.ASSET());
        vars.expectedAsset = address(dai);
        assertEq(vars.actualAsset, vars.expectedAsset, "asset");

        vars.actualExpiration = constructedInstant.EXPIRATION();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualIpfsCID = constructedInstant.ipfsCID();
        vars.expectedIpfsCID = defaults.IPFS_CID();
        assertEq(vars.actualIpfsCID, vars.expectedIpfsCID, "ipfsCID");

        vars.actualMerkleRoot = constructedInstant.MERKLE_ROOT();
        vars.expectedMerkleRoot = defaults.MERKLE_ROOT();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        vars.actualName = constructedInstant.name();
        vars.expectedName = defaults.NAME_BYTES32();
        assertEq(bytes32(abi.encodePacked(vars.actualName)), vars.expectedName, "name");
    }
}
