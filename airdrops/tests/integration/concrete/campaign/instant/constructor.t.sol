// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";

import { MerkleInstant_Integration_Shared_Test } from "./MerkleInstant.t.sol";

contract Constructor_MerkleInstant_Integration_Test is MerkleInstant_Integration_Shared_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactoryInstant));

        // Deploy the SablierMerkleInstant contract.
        SablierMerkleInstant constructedInstant =
            new SablierMerkleInstant(merkleInstantConstructorParams(), users.campaignCreator);

        // SablierMerkleBase
        assertEq(constructedInstant.admin(), users.campaignCreator, "admin");
        assertEq(constructedInstant.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedInstant.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(constructedInstant.FACTORY(), address(merkleFactoryInstant), "factory");
        assertEq(constructedInstant.ipfsCID(), IPFS_CID, "ipfsCID");
        assertEq(constructedInstant.MERKLE_ROOT(), MERKLE_ROOT, "merkleRoot");
        assertEq(constructedInstant.minimumFee(), MINIMUM_FEE, "minimum fee");
        assertEq(constructedInstant.ORACLE(), address(oracle), "oracle");
        assertEq(address(constructedInstant.TOKEN()), address(dai), "token");
    }
}
