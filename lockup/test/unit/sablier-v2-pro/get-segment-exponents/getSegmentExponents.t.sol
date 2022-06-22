// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";

contract SablierV2Pro__UnitTest__GetSegmentExponents is SablierV2ProUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetSegmentExponents__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        SD59x18[] memory actualSegmentExponents = sablierV2Pro.getSegmentExponents(nonStreamId);
        SD59x18[] memory expectedSegmentExponents;
        assertEq(actualSegmentExponents, expectedSegmentExponents);
    }

    /// @dev When the stream exists, it should return the correct segment amounts.
    function testGetSegmentExponents() external {
        uint256 daiStreamId = createDefaultDaiStream();
        SD59x18[] memory actualSegmentExponents = sablierV2Pro.getSegmentExponents(daiStreamId);
        SD59x18[] memory expectedSegmentExponents = daiStream.segmentExponents;
        assertEq(actualSegmentExponents, expectedSegmentExponents);
    }
}
