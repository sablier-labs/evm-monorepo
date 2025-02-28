// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryInstant } from "src/SablierMerkleFactoryInstant.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryInstant_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryInstant constructedFactoryInstant =
            new SablierMerkleFactoryInstant(users.admin, MINIMUM_FEE, address(oracle));

        assertEq(constructedFactoryInstant.admin(), users.admin, "factory admin");
        assertEq(constructedFactoryInstant.oracle(), address(oracle), "oracle");
        assertEq(constructedFactoryInstant.minimumFee(), MINIMUM_FEE, "minimum fee");
    }
}
