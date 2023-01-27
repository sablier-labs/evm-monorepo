// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Unit_Test } from "../Unit.t.sol";

/// @title Comptroller_Unit_Test
/// @notice Dummy contract only needed for providing naming context in the test traces.
abstract contract Comptroller_Unit_Test is Unit_Test {
    function setUp() public virtual override {
        Unit_Test.setUp();
    }
}
