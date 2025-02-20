// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";

import { MerkleInstant_Integration_Shared_Test } from "./MerkleInstant.t.sol";

contract Constructor_MerkleInstant_Integration_Test is MerkleInstant_Integration_Shared_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        resetPrank(address(merkleFactoryInstant));

        SablierMerkleInstant constructedInstant =
            new SablierMerkleInstant(merkleInstantConstructorParams(), users.campaignOwner);

        assertEq(constructedInstant.admin(), users.campaignOwner, "admin");
        assertEq(constructedInstant.campaignName(), defaults.CAMPAIGN_NAME(), "campaign name");
        assertEq(constructedInstant.EXPIRATION(), defaults.EXPIRATION(), "expiration");
        assertEq(constructedInstant.FACTORY(), address(merkleFactoryInstant), "factory");
        assertEq(constructedInstant.MINIMUM_FEE(), defaults.MINIMUM_FEE(), "minimum fee");
        assertEq(constructedInstant.ipfsCID(), defaults.IPFS_CID(), "ipfsCID");
        assertEq(constructedInstant.MERKLE_ROOT(), defaults.MERKLE_ROOT(), "merkleRoot");
        assertEq(address(constructedInstant.TOKEN()), address(dai), "token");
    }
}
