// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

contract Constructor_MerkleInstant_Integration_Test is Integration_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        setMsgSender(address(factoryMerkleInstant));

        // Deploy the SablierMerkleInstant contract.
        SablierMerkleInstant constructedInstant =
            new SablierMerkleInstant(merkleInstantConstructorParams(), users.campaignCreator, address(comptroller));

        // SablierMerkleBase
        assertEq(constructedInstant.admin(), users.campaignCreator, "admin");
        assertEq(constructedInstant.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedInstant.CAMPAIGN_START_TIME(), CAMPAIGN_START_TIME, "campaign start time");
        assertEq(constructedInstant.COMPTROLLER(), address(comptroller), "comptroller");
        assertEq(constructedInstant.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(constructedInstant.ipfsCID(), IPFS_CID, "IPFS CID");
        assertEq(constructedInstant.IS_SABLIER_MERKLE(), true, "is sablier merkle");
        assertEq(constructedInstant.MERKLE_ROOT(), MERKLE_ROOT, "merkleRoot");
        assertEq(constructedInstant.minFeeUSD(), AIRDROP_MIN_FEE_USD, "min fee USD");
        assertEq(address(constructedInstant.TOKEN()), address(dai), "token");
    }
}
