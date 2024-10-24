// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactory } from "src/periphery/SablierMerkleFactory.sol";

import { MerkleCampaign_Integration_Test } from "../MerkleCampaign.t.sol";

contract Constructor_MerkleFactory_Integration_Test is MerkleCampaign_Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactory constructedFactory = new SablierMerkleFactory(users.admin);

        address actualAdmin = constructedFactory.admin();
        assertEq(actualAdmin, users.admin, "factory admin");

        uint256 actualDefaultSablierFee = constructedFactory.defaultSablierFee();
        assertEq(actualDefaultSablierFee, 0, "default sablier fee");
    }
}
