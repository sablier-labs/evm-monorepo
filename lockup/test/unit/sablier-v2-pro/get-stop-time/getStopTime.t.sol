// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__StopTime__StreamNonExistent is SablierV2ProUnitTest {
    /// @dev it should return zero.
    function testGetStopTime() external {
        uint256 nonStreamId = 1729;
        uint256 actualStopTime = sablierV2Pro.getStopTime(nonStreamId);
        uint256 expectedStopTime = 0;
        assertEq(actualStopTime, expectedStopTime);
    }
}

contract StreamExistent {}

contract SablierV2Pro__StopTime is SablierV2ProUnitTest, StreamExistent {
    /// @dev it should return the correct stop time.
    function testGetStopTime() external {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256 actualStopTime = sablierV2Pro.getStopTime(daiStreamId);
        uint256 expectedStopTime = daiStream.stopTime;
        assertEq(actualStopTime, expectedStopTime);
    }
}
