// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryLL } from "src/SablierMerkleFactoryLL.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryLL_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryLL constructedFactory =
            new SablierMerkleFactoryLL(users.admin, MINIMUM_FEE, address(oracle));

        // SablierMerkleFactoryBase
        assertEq(constructedFactory.admin(), users.admin, "factory admin");
        assertEq(constructedFactory.MAX_FEE(), MAX_FEE, "max fee");
        assertEq(constructedFactory.minimumFee(), MINIMUM_FEE, "minimum fee");
        assertEq(constructedFactory.oracle(), address(oracle), "oracle");
    }
}
