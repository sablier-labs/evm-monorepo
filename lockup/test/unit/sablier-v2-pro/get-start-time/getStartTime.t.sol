// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__StartTime__StreamNonExistent is SablierV2ProUnitTest {
    /// @dev it should return zero.
    function testGetStartTime() external {
        uint256 nonStreamId = 1729;
        uint256 actualStartTime = sablierV2Pro.getStartTime(nonStreamId);
        uint256 expectedStartTime = 0;
        assertEq(actualStartTime, expectedStartTime);
    }
}

contract StreamExistent {}

contract SablierV2Pro__StartTime is SablierV2ProUnitTest, StreamExistent {
    /// @dev it should return the correct start time.
    function testGetStartTime() external {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256 actualStartTime = sablierV2Pro.getStartTime(daiStreamId);
        uint256 expectedStartTime = daiStream.startTime;
        assertEq(actualStartTime, expectedStartTime);
    }
}
