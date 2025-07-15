// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

contract Constructor_MerkleVCA_Integration_Test is Integration_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        setMsgSender(address(factoryMerkleVCA));

        // Deploy the SablierMerkleVCA contract.
        SablierMerkleVCA constructedVCA =
            new SablierMerkleVCA(merkleVCAConstructorParams(), users.campaignCreator, address(comptroller));

        // SablierMerkleBase
        assertEq(constructedVCA.admin(), users.campaignCreator, "admin");
        assertEq(constructedVCA.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedVCA.CAMPAIGN_START_TIME(), CAMPAIGN_START_TIME, "campaign start time");
        assertEq(constructedVCA.COMPTROLLER(), address(comptroller), "comptroller");
        assertEq(constructedVCA.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(constructedVCA.ipfsCID(), IPFS_CID, "IPFS CID");
        assertEq(constructedVCA.IS_SABLIER_MERKLE(), true, "is sablier merkle");
        assertEq(constructedVCA.MERKLE_ROOT(), MERKLE_ROOT, "Merkle root");
        assertEq(constructedVCA.minFeeUSD(), AIRDROP_MIN_FEE_USD, "min fee USD");
        assertEq(address(constructedVCA.TOKEN()), address(dai), "token");

        // SablierMerkleVCA
        assertEq(constructedVCA.UNLOCK_PERCENTAGE(), VCA_UNLOCK_PERCENTAGE, "unlock percentage");
        assertEq(constructedVCA.VESTING_END_TIME(), VCA_END_TIME, "vesting end time");
        assertEq(constructedVCA.VESTING_START_TIME(), VCA_START_TIME, "vesting start time");
        assertEq(constructedVCA.totalForgoneAmount(), 0, "total forgone amount");
    }
}
