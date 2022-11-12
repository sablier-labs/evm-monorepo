// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SD59x18 } from "@prb/math/SD59x18.sol";

import { SablierV2ProBaseTest } from "../SablierV2ProBaseTest.t.sol";

contract GetSegmentExponents__Tests is SablierV2ProBaseTest {
    /// @dev it should return zero.
    function testGetSegmentExponents__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        SD59x18[] memory actualSegmentExponents = sablierV2Pro.getSegmentExponents(nonStreamId);
        SD59x18[] memory expectedSegmentExponents;
        assertEq(actualSegmentExponents, expectedSegmentExponents);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segment amounts.
    function testGetSegmentExponents() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        SD59x18[] memory actualSegmentExponents = sablierV2Pro.getSegmentExponents(daiStreamId);
        SD59x18[] memory expectedSegmentExponents = daiStream.segmentExponents;
        assertEq(actualSegmentExponents, expectedSegmentExponents);
    }
}
