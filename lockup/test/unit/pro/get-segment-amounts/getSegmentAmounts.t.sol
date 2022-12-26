// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract GetSegmentAmounts__Test is ProTest {
    /// @dev it should return zero.
    function testGetSegmentAmounts__StreamNonExistents() external {
        uint256 nonStreamId = 1729;
        uint128[] memory actualSegmentAmounts = pro.getSegmentAmounts(nonStreamId);
        uint128[] memory expectedSegmentAmounts;
        assertEqUint128Array(actualSegmentAmounts, expectedSegmentAmounts);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segment amounts.
    function testGetSegmentAmounts() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        uint128[] memory actualSegmentAmounts = pro.getSegmentAmounts(defaultStreamId);
        uint128[] memory expectedSegmentAmounts = defaultStream.segmentAmounts;
        assertEqUint128Array(actualSegmentAmounts, expectedSegmentAmounts);
    }
}
