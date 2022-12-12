// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract GetSegmentExponents__Test is SablierV2ProTest {
    /// @dev it should return zero.
    function testGetSegmentExponents__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        int64[] memory actualSegmentExponents = sablierV2Pro.getSegmentExponents(nonStreamId);
        int64[] memory expectedSegmentExponents;
        assertEqInt64Array(actualSegmentExponents, expectedSegmentExponents);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segment amounts.
    function testGetSegmentExponents() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        int64[] memory actualSegmentExponents = sablierV2Pro.getSegmentExponents(daiStreamId);
        int64[] memory expectedSegmentExponents = daiStream.segmentExponents;
        assertEqInt64Array(actualSegmentExponents, expectedSegmentExponents);
    }
}
