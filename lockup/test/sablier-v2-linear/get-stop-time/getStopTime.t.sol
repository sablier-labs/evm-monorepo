// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearBaseTest } from "../SablierV2LinearBaseTest.t.sol";

contract GetStopTime__Tests is SablierV2LinearBaseTest {
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
        uint256 daiStreamId = createDefaultDaiStream();
        uint256 actualStopTime = sablierV2Linear.getStopTime(daiStreamId);
        uint256 expectedStopTime = daiStream.stopTime;
        assertEq(actualStopTime, expectedStopTime);
    }
}
