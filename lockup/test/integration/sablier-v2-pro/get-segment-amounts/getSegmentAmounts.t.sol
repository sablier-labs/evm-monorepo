// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract GetSegmentAmounts__Test is SablierV2ProTest {
    /// @dev it should return zero.
    function testGetSegmentAmounts__StreamNonExistents() external {
        uint256 nonStreamId = 1729;
        uint128[] memory actualSegmentAmounts = sablierV2Pro.getSegmentAmounts(nonStreamId);
        uint128[] memory expectedSegmentAmounts;
        assertEqUint128Array(actualSegmentAmounts, expectedSegmentAmounts);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segment amounts.
    function testGetSegmentAmounts() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        uint128[] memory actualSegmentAmounts = sablierV2Pro.getSegmentAmounts(daiStreamId);
        uint128[] memory expectedSegmentAmounts = daiStream.segmentAmounts;
        assertEqUint128Array(actualSegmentAmounts, expectedSegmentAmounts);
    }
}
