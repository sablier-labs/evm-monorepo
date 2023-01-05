// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Range } from "src/types/Structs.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract GetRange__LinearTest is LinearTest {
    /// @dev it should return a zeroed out range.
    function testGetRange__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        Range memory actualRange = linear.getRange(nonStreamId);
        Range memory expectedRange = Range(0, 0, 0);
        assertEq(actualRange, expectedRange);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the range.
    function testGetRange() external StreamExistent {
        uint256 streamId = createDefaultStream();
        Range memory actualRange = linear.getRange(streamId);
        Range memory expectedRange = DEFAULT_RANGE;
        assertEq(actualRange, expectedRange);
    }
}
