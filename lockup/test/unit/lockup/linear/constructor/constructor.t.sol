// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract Constructor_Linear_Unit_Test is Linear_Unit_Test {
    /// @dev it should initialize all the values correctly.
    function test_Constructor() external {
        // {SablierV2-constructor}
        address actualAdmin = linear.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualComptroller = address(linear.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        UD60x18 actualMaxFee = linear.MAX_FEE();
        UD60x18 expectedMaxFee = DEFAULT_MAX_FEE;
        assertEq(actualMaxFee, expectedMaxFee, "MAX_FEE");

        // {SablierV2Lockup-constructor}
        uint256 actualStreamId = linear.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");
    }
}
