// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_MerkleInstant_Integration_Test is Integration_Test {
    /// @dev Needed to prevent "Stack too deep" error
    struct Vars {
        address actualAdmin;
        string actualCampaignName;
        uint40 actualExpiration;
        address actualFactory;
        string actualIpfsCID;
        bytes32 actualMerkleRoot;
        uint256 actualFee;
        address actualToken;
        address expectedAdmin;
        string expectedCampaignName;
        uint40 expectedExpiration;
        address expectedFactory;
        string expectedIpfsCID;
        bytes32 expectedMerkleRoot;
        uint256 expectedFee;
        address expectedToken;
    }

    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactory));

        SablierMerkleInstant constructedInstant =
            new SablierMerkleInstant(merkleInstantConstructorParams(), users.campaignOwner);

        Vars memory vars;

        vars.actualAdmin = constructedInstant.admin();
        vars.expectedAdmin = users.campaignOwner;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualCampaignName = constructedInstant.campaignName();
        vars.expectedCampaignName = defaults.CAMPAIGN_NAME();
        assertEq(vars.actualCampaignName, vars.expectedCampaignName, "campaign name");

        vars.actualExpiration = constructedInstant.EXPIRATION();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualFactory = constructedInstant.FACTORY();
        vars.expectedFactory = address(merkleFactory);
        assertEq(vars.actualFactory, vars.expectedFactory, "factory");

        vars.actualFee = constructedInstant.FEE();
        vars.expectedFee = defaults.FEE();
        assertEq(vars.actualFee, vars.expectedFee, "fee");

        vars.actualIpfsCID = constructedInstant.ipfsCID();
        vars.expectedIpfsCID = defaults.IPFS_CID();
        assertEq(vars.actualIpfsCID, vars.expectedIpfsCID, "ipfsCID");

        vars.actualMerkleRoot = constructedInstant.MERKLE_ROOT();
        vars.expectedMerkleRoot = defaults.MERKLE_ROOT();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        vars.actualToken = address(constructedInstant.TOKEN());
        vars.expectedToken = address(dai);
        assertEq(vars.actualToken, vars.expectedToken, "token");
    }
}
