// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactory } from "src/SablierMerkleFactory.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_MerkleFactory_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactory constructedFactory = new SablierMerkleFactory(users.admin);

        address actualAdmin = constructedFactory.admin();
        assertEq(actualAdmin, users.admin, "factory admin");

        uint256 actualDefaultFee = constructedFactory.defaultFee();
        assertEq(actualDefaultFee, 0, "default fee");
    }
}
