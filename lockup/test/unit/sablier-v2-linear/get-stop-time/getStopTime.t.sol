// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__StopTime__StreamNonExistent is SablierV2LinearUnitTest {
    /// @dev it should return zero.
    function testGetStopTime() external {
        uint256 nonStreamId = 1729;
        uint256 actualStopTime = sablierV2Linear.getStopTime(nonStreamId);
        uint256 expectedStopTime = 0;
        assertEq(actualStopTime, expectedStopTime);
    }
}

contract StreamExistent {}

contract SablierV2Linear__StopTime is SablierV2LinearUnitTest, StreamExistent {
    /// @dev it should return the correct stop time.
    function testGetStopTime() external {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256 actualStopTime = sablierV2Linear.getStopTime(daiStreamId);
        uint256 expectedStopTime = daiStream.stopTime;
        assertEq(actualStopTime, expectedStopTime);
    }
}
