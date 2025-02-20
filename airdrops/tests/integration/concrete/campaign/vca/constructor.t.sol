// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";

import { MerkleVCA_Integration_Shared_Test } from "./MerkleVCA.t.sol";

contract Constructor_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactoryVCA));

        SablierMerkleVCA actualMerkleVCA = new SablierMerkleVCA(merkleVCAConstructorParams(), users.campaignOwner);

        assertEq(actualMerkleVCA.admin(), users.campaignOwner, "admin");
        assertEq(actualMerkleVCA.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(actualMerkleVCA.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(actualMerkleVCA.FACTORY(), address(merkleFactoryVCA), "factory");
        assertEq(actualMerkleVCA.MINIMUM_FEE(), MINIMUM_FEE, "minimum fee");
        assertEq(actualMerkleVCA.ipfsCID(), IPFS_CID, "ipfsCID");
        assertEq(actualMerkleVCA.MERKLE_ROOT(), MERKLE_ROOT, "merkleRoot");
        assertEq(actualMerkleVCA.forgoneAmount(), 0, "forgoneAmount");
        assertEq(actualMerkleVCA.timestamps().start, RANGED_STREAM_START_TIME, "unlock start");
        assertEq(actualMerkleVCA.timestamps().end, RANGED_STREAM_END_TIME, "unlock end");
        assertEq(address(actualMerkleVCA.TOKEN()), address(dai), "token");
    }
}
