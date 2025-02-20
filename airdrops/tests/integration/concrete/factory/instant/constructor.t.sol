// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryInstant } from "src/SablierMerkleFactoryInstant.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryInstant_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryInstant constructedFactoryInstant =
            new SablierMerkleFactoryInstant(users.admin, MINIMUM_FEE);

        address actualAdmin = constructedFactoryInstant.admin();
        assertEq(actualAdmin, users.admin, "factory admin");

        uint256 actualMinimumFee = constructedFactoryInstant.minimumFee();
        uint256 expectedMinimumFee = MINIMUM_FEE;
        assertEq(actualMinimumFee, expectedMinimumFee, "minimum fee");
    }
}
