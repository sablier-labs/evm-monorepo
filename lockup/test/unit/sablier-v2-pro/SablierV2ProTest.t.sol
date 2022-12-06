// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { UnitTest } from "../UnitTest.t.sol";

import { SablierV2Pro } from "src/SablierV2Pro.sol";

/// @title SablierV2ProTest
/// @notice Common contract members needed across SablierV2Pro unit tests
abstract contract SablierV2ProTest is UnitTest {
    SablierV2Pro internal sablierV2Pro;

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        sablierV2Pro = new SablierV2Pro({ maxSegmentCount: MAX_SEGMENT_COUNT });
    }
}
