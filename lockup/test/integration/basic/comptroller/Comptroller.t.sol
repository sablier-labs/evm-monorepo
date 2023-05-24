// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Integration_Test } from "../../Integration.t.sol";

/// @title Comptroller_Integration_Basic_Test
/// @notice Dummy contract only needed for providing naming context in the test traces.
abstract contract Comptroller_Integration_Basic_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();
    }
}
