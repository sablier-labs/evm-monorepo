// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Range } from "src/types/Structs.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetRange_Linear_Unit_Test is Linear_Unit_Test {
    /// @dev it should return a zeroed out range.
    function test_GetRange_StreamNull() external {
        uint256 nullStreamId = 1729;
        Range memory actualRange = linear.getRange(nullStreamId);
        Range memory expectedRange = Range(0, 0, 0);
        assertEq(actualRange, expectedRange);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the range.
    function test_GetRange() external streamNonNull {
        uint256 streamId = createDefaultStream();
        Range memory actualRange = linear.getRange(streamId);
        Range memory expectedRange = DEFAULT_RANGE;
        assertEq(actualRange, expectedRange);
    }
}
