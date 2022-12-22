// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";

import { ProTest } from "../ProTest.t.sol";

contract GetSegmentExponents__Test is ProTest {
    /// @dev it should return zero.
    function testGetSegmentExponents__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        SD1x18[] memory actualSegmentExponents = sablierV2Pro.getSegmentExponents(nonStreamId);
        SD1x18[] memory expectedSegmentExponents;
        assertEq(actualSegmentExponents, expectedSegmentExponents);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segment amounts.
    function testGetSegmentExponents() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        SD1x18[] memory actualSegmentExponents = sablierV2Pro.getSegmentExponents(daiStreamId);
        SD1x18[] memory expectedSegmentExponents = daiStream.segmentExponents;
        assertEq(actualSegmentExponents, expectedSegmentExponents);
    }
}
