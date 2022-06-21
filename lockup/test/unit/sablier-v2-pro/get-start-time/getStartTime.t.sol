// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__UnitTest__StartTime is SablierV2ProUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetStartTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualStartTime = sablierV2Pro.getStartTime(nonStreamId);
        uint256 expectedStartTime = 0;
        assertEq(actualStartTime, expectedStartTime);
    }

    /// @dev When the stream exists, it should return the correct start time.
    function testGetStartTime() external {
        uint256 streamId = createDefaultDaiStream();
        uint256 actualStartTime = sablierV2Pro.getStartTime(streamId);
        uint256 expectedStartTime = daiStream.startTime;
        assertEq(actualStartTime, expectedStartTime);
    }
}
