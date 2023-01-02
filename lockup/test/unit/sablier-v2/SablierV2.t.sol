// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2 } from "src/SablierV2.sol";

import { UnitTest } from "../UnitTest.t.sol";

/// @title SablierV2Test
/// @notice Dummy contract only needed to provide naming context in the test suites.
abstract contract SablierV2Test is UnitTest {
    function setUp() public virtual override {
        super.setUp();
    }
}
