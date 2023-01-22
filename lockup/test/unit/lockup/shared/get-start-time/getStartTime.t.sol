// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetStartTime_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should return zero.
    function test_GetStartTime_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint40 actualStartTime = lockup.getStartTime(nullStreamId);
        uint40 expectedStartTime = 0;
        assertEq(actualStartTime, expectedStartTime, "startTime");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct start time.
    function test_GetStartTime() external streamNonNull {
        uint256 streamId = createDefaultStream();
        uint40 actualStartTime = lockup.getStartTime(streamId);
        uint40 expectedStartTime = DEFAULT_START_TIME;
        assertEq(actualStartTime, expectedStartTime, "startTime");
    }
}
