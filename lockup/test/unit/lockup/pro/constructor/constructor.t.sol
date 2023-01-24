// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract Constructor_Pro_Unit_Test is Pro_Unit_Test {
    /// @dev it should initialize all the values correctly.
    function test_Constructor() external {
        // {SablierV2-constructor}
        address actualAdmin = pro.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualComptroller = address(pro.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        UD60x18 actualMaxFee = pro.MAX_FEE();
        UD60x18 expectedMaxFee = DEFAULT_MAX_FEE;
        assertEq(actualMaxFee, expectedMaxFee, "MAX_FEE");

        // {SablierV2Lockup-constructor}
        uint256 actualStreamId = pro.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        // {SablierV2LockupPro-constructor}
        uint256 actualMaxSegmentCount = pro.MAX_SEGMENT_COUNT();
        uint256 expectedMaxSegmentCount = DEFAULT_MAX_SEGMENT_COUNT;
        assertEq(actualMaxSegmentCount, expectedMaxSegmentCount, "MAX_SEGMENT_COUNT");
    }
}
