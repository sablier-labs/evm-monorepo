// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleInstant } from "src/periphery/SablierMerkleInstant.sol";

import { MerkleCampaign_Integration_Test } from "../MerkleCampaign.t.sol";

contract Constructor_MerkleInstant_Integration_Test is MerkleCampaign_Integration_Test {
    /// @dev Needed to prevent "Stack too deep" error
    struct Vars {
        address actualAdmin;
        address actualAsset;
        uint40 actualExpiration;
        address actualFactory;
        string actualIpfsCID;
        bytes32 actualMerkleRoot;
        string actualName;
        uint256 actualSablierFee;
        address expectedAdmin;
        address expectedAsset;
        uint40 expectedExpiration;
        address expectedFactory;
        string expectedIpfsCID;
        bytes32 expectedMerkleRoot;
        bytes32 expectedName;
        uint256 expectedSablierFee;
    }

    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactory));

        SablierMerkleInstant constructedInstant =
            new SablierMerkleInstant(defaults.baseParams(), defaults.DEFAULT_SABLIER_FEE());

        Vars memory vars;

        vars.actualAdmin = constructedInstant.admin();
        vars.expectedAdmin = users.campaignOwner;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualAsset = address(constructedInstant.ASSET());
        vars.expectedAsset = address(dai);
        assertEq(vars.actualAsset, vars.expectedAsset, "asset");

        vars.actualExpiration = constructedInstant.EXPIRATION();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualFactory = constructedInstant.FACTORY();
        vars.expectedFactory = address(merkleFactory);
        assertEq(vars.actualFactory, vars.expectedFactory, "factory");

        vars.actualIpfsCID = constructedInstant.ipfsCID();
        vars.expectedIpfsCID = defaults.IPFS_CID();
        assertEq(vars.actualIpfsCID, vars.expectedIpfsCID, "ipfsCID");

        vars.actualMerkleRoot = constructedInstant.MERKLE_ROOT();
        vars.expectedMerkleRoot = defaults.MERKLE_ROOT();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        vars.actualName = constructedInstant.name();
        vars.expectedName = defaults.NAME_BYTES32();
        assertEq(bytes32(abi.encodePacked(vars.actualName)), vars.expectedName, "name");

        vars.actualSablierFee = constructedInstant.SABLIER_FEE();
        vars.expectedSablierFee = defaults.DEFAULT_SABLIER_FEE();
        assertEq(vars.actualSablierFee, vars.expectedSablierFee, "sablierFee");
    }
}
