// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetRange_Linear_Unit_Test is Linear_Unit_Test {
    /// @dev it should return a zeroed out range.
    function test_GetRange_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupLinear.Range memory actualRange = linear.getRange(nullStreamId);
        LockupLinear.Range memory expectedRange = LockupLinear.Range(0, 0, 0);
        assertEq(actualRange, expectedRange);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the range.
    function test_GetRange() external streamNonNull {
        uint256 streamId = createDefaultStream();
        LockupLinear.Range memory actualRange = linear.getRange(streamId);
        LockupLinear.Range memory expectedRange = DEFAULT_LINEAR_RANGE;
        assertEq(actualRange, expectedRange);
    }
}
