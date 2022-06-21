// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__StopTime is SablierV2LinearUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetStopTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualStopTime = sablierV2Linear.getStopTime(nonStreamId);
        uint256 expectedStopTime = 0;
        assertEq(actualStopTime, expectedStopTime);
    }

    /// @dev When the stream exists, it should return the correct stop time.
    function testGetStopTime() external {
        uint256 streamId = createDefaultDaiStream();
        uint256 actualStopTime = sablierV2Linear.getStopTime(streamId);
        uint256 expectedStopTime = daiStream.stopTime;
        assertEq(actualStopTime, expectedStopTime);
    }
}
