// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Shared_Lockup_Unit_Test } from "../SharedTest.t.sol";

abstract contract GetStopTime_Unit_Test is Shared_Lockup_Unit_Test {
    /// @dev it should return zero.
    function test_GetStopTime_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint40 actualStopTime = lockup.getStopTime(nullStreamId);
        uint40 expectedStopTime = 0;
        assertEq(actualStopTime, expectedStopTime, "stopTime");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct stop time.
    function test_GetStopTime() external streamNonNull {
        uint256 streamId = createDefaultStream();
        uint40 actualStopTime = lockup.getStopTime(streamId);
        uint40 expectedStopTime = DEFAULT_STOP_TIME;
        assertEq(actualStopTime, expectedStopTime, "stopTime");
    }
}
