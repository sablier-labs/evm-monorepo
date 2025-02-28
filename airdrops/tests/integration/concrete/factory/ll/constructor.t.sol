// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryLL } from "src/SablierMerkleFactoryLL.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryLL_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryLL constructedFactoryLL =
            new SablierMerkleFactoryLL(users.admin, MINIMUM_FEE, address(oracle));

        assertEq(constructedFactoryLL.admin(), users.admin, "factory admin");
        assertEq(constructedFactoryLL.oracle(), address(oracle), "oracle");
        assertEq(constructedFactoryLL.minimumFee(), MINIMUM_FEE, "minimum fee");
    }
}
