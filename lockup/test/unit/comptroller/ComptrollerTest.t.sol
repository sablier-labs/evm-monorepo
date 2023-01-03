// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { UnitTest } from "../UnitTest.t.sol";

/// @title ComptrollerTest
/// @notice Dummy contract only needed for providing naming context in the test logs.
abstract contract ComptrollerTest is UnitTest {
    function setUp() public virtual override {
        UnitTest.setUp();
    }
}
