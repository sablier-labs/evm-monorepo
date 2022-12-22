// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract GetStartTime__Test is ProTest {
    /// @dev it should return zero.
    function testGetStartTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualStartTime = pro.getStartTime(nonStreamId);
        uint256 expectedStartTime = 0;
        assertEq(actualStartTime, expectedStartTime);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct start time.
    function testGetStartTime() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256 actualStartTime = pro.getStartTime(daiStreamId);
        uint256 expectedStartTime = daiStream.startTime;
        assertEq(actualStartTime, expectedStartTime);
    }
}
