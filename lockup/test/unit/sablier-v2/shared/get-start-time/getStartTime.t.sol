// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetStartTime_Test is SharedTest {
    /// @dev it should return zero.
    function test_GetStartTime_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint40 actualStartTime = sablierV2.getStartTime(nonStreamId);
        uint40 expectedStartTime = 0;
        assertEq(actualStartTime, expectedStartTime);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct start time.
    function test_GetStartTime() external StreamExistent {
        uint256 streamId = createDefaultStream();
        uint40 actualStartTime = sablierV2.getStartTime(streamId);
        uint40 expectedStartTime = DEFAULT_START_TIME;
        assertEq(actualStartTime, expectedStartTime);
    }
}
