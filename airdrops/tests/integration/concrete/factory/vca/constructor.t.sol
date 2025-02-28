// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryVCA } from "src/SablierMerkleFactoryVCA.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryVCA_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryVCA constructedFactoryVCA =
            new SablierMerkleFactoryVCA(users.admin, MINIMUM_FEE, address(oracle));

        assertEq(constructedFactoryVCA.admin(), users.admin, "factory admin");
        assertEq(constructedFactoryVCA.oracle(), address(oracle), "oracle");
        assertEq(constructedFactoryVCA.minimumFee(), MINIMUM_FEE, "minimum fee");
    }
}
