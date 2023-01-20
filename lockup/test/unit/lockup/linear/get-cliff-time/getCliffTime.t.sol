// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Linear_Test } from "../Linear.t.sol";

contract GetCliffTime_Linear_Test is Linear_Test {
    /// @dev it should return zero.
    function test_GetCliffTime_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint40 actualCliffTime = linear.getCliffTime(nullStreamId);
        uint40 expectedCliffTime = 0;
        assertEq(actualCliffTime, expectedCliffTime, "cliffTime");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct cliff time.
    function test_GetCliffTime() external streamNonNull {
        uint256 streamId = createDefaultStream();
        uint40 actualCliffTime = linear.getCliffTime(streamId);
        uint40 expectedCliffTime = DEFAULT_CLIFF_TIME;
        assertEq(actualCliffTime, expectedCliffTime, "cliffTime");
    }
}
