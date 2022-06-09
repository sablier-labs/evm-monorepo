// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__StartTime__UnitTest is SablierV2LinearUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetStartTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualStartTime = sablierV2Linear.getStartTime(nonStreamId);
        uint256 expectedStartTime = 0;
        assertEq(actualStartTime, expectedStartTime);
    }

    /// @dev When the stream exists, it should return the correct start time.
    function testGetStartTime() external {
        uint256 streamId = createDefaultStream();
        uint256 actualStartTime = sablierV2Linear.getStartTime(streamId);
        uint256 expectedStartTime = stream.startTime;
        assertEq(actualStartTime, expectedStartTime);
    }
}
