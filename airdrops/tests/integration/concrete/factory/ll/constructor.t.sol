// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactoryLL } from "src/SablierMerkleFactoryLL.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_MerkleFactoryLL_Integration_Test is Integration_Test {
    function test_Constructor() external {
        SablierMerkleFactoryLL constructedFactoryLL = new SablierMerkleFactoryLL(users.admin, MINIMUM_FEE);

        address actualAdmin = constructedFactoryLL.admin();
        assertEq(actualAdmin, users.admin, "factory admin");

        uint256 actualMinimumFee = constructedFactoryLL.minimumFee();
        uint256 expectedMinimumFee = MINIMUM_FEE;
        assertEq(actualMinimumFee, expectedMinimumFee, "minimum fee");
    }
}
