// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryVCA } from "src/SablierMerkleFactoryVCA.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryVCA_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryVCA constructedFactoryVCA = new SablierMerkleFactoryVCA(users.admin, defaults.MINIMUM_FEE());

        address actualAdmin = constructedFactoryVCA.admin();
        assertEq(actualAdmin, users.admin, "factory admin");

        uint256 actualMinimumFee = constructedFactoryVCA.minimumFee();
        uint256 expectedMinimumFee = defaults.MINIMUM_FEE();
        assertEq(actualMinimumFee, expectedMinimumFee, "minimum fee");
    }
}
