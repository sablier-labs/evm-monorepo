// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { UnitTest } from "../UnitTest.t.sol";

import { SablierV2Linear } from "src/SablierV2Linear.sol";

/// @title SablierV2LinearTest
/// @notice Common contract members needed across SablierV2Linear unit tests
abstract contract SablierV2LinearTest is UnitTest {
    SablierV2Linear internal sablierV2Linear;

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        sablierV2Linear = new SablierV2Linear();
    }
}
