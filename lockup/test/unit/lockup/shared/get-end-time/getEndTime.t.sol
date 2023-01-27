// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetEndTime_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should return zero.
    function test_GetEndTime_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint40 actualEndTime = lockup.getEndTime(nullStreamId);
        uint40 expectedEndTime = 0;
        assertEq(actualEndTime, expectedEndTime, "endTime");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct end time.
    function test_GetEndTime() external streamNonNull {
        uint256 streamId = createDefaultStream();
        uint40 actualEndTime = lockup.getEndTime(streamId);
        uint40 expectedEndTime = DEFAULT_END_TIME;
        assertEq(actualEndTime, expectedEndTime, "endTime");
    }
}
