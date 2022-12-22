// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { LinearTest } from "../LinearTest.t.sol";

contract GetStopTime__Test is LinearTest {
    /// @dev it should return zero.
    function testGetStopTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualStopTime = sablierV2Linear.getStopTime(nonStreamId);
        uint256 expectedStopTime = 0;
        assertEq(actualStopTime, expectedStopTime);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct stop time.
    function testGetStopTime() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        uint256 actualStopTime = sablierV2Linear.getStopTime(defaultStreamId);
        uint256 expectedStopTime = defaultStream.stopTime;
        assertEq(actualStopTime, expectedStopTime);
    }
}
