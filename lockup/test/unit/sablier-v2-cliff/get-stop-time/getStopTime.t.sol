// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__StopTime__UnitTest is SablierV2CliffUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetStopTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualStopTime = sablierV2Cliff.getStopTime(nonStreamId);
        uint256 expectedStopTime = 0;
        assertEq(actualStopTime, expectedStopTime);
    }

    /// @dev When the stream exists, it should return the correct stop time.
    function testGetStopTime() external {
        uint256 streamId = createDefaultStream();
        uint256 actualStopTime = sablierV2Cliff.getStopTime(streamId);
        uint256 expectedStopTime = stream.stopTime;
        assertEq(actualStopTime, expectedStopTime);
    }
}
