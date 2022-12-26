// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract GetStopTime__Test is ProTest {
    /// @dev it should return zero.
    function testGetStopTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualStopTime = pro.getStopTime(nonStreamId);
        uint256 expectedStopTime = 0;
        assertEq(actualStopTime, expectedStopTime);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct stop time.
    function testGetStopTime() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        uint256 actualStopTime = pro.getStopTime(defaultStreamId);
        uint256 expectedStopTime = defaultStream.stopTime;
        assertEq(actualStopTime, expectedStopTime);
    }
}
