// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryLT } from "src/SablierMerkleFactoryLT.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryLT_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryLT constructedFactoryLT = new SablierMerkleFactoryLT(users.admin, defaults.MINIMUM_FEE());

        address actualAdmin = constructedFactoryLT.admin();
        assertEq(actualAdmin, users.admin, "factory admin");

        uint256 actualMinimumFee = constructedFactoryLT.minimumFee();
        uint256 expectedMinimumFee = defaults.MINIMUM_FEE();
        assertEq(actualMinimumFee, expectedMinimumFee, "minimum fee");
    }
}
