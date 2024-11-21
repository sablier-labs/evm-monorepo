// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Precompiles } from "precompiles/Precompiles.sol";
import { LibString } from "solady/src/utils/LibString.sol";
import { Base_Test } from "./../Base.t.sol";

contract Precompiles_Test is Base_Test {
    using LibString for address;

    Precompiles internal precompiles = new Precompiles();

    modifier onlyTestOptimizedProfile() {
        if (isTestOptimizedProfile()) {
            _;
        }
    }

    function test_DeployMerkleFactory() external onlyTestOptimizedProfile {
        address actualFactory = address(precompiles.deployMerkleFactory(users.admin));
        address expectedFactory = address(deployOptimizedMerkleFactory(users.admin));
        assertEq(actualFactory.code, expectedFactory.code, "bytecodes mismatch");
    }
}
