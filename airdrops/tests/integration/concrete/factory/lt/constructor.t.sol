// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryLT } from "src/SablierMerkleFactoryLT.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryLT_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryLT constructedFactory =
            new SablierMerkleFactoryLT(users.admin, MINIMUM_FEE, address(oracle));

        // SablierMerkleFactoryBase
        assertEq(constructedFactory.admin(), users.admin, "factory admin");
        assertEq(constructedFactory.MAX_FEE(), MAX_FEE, "max fee");
        assertEq(constructedFactory.minimumFee(), MINIMUM_FEE, "minimum fee");
        assertEq(constructedFactory.oracle(), address(oracle), "oracle");
    }
}
