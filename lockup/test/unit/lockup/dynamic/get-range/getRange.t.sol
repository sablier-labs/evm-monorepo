// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract GetRange_Dynamic_Unit_Test is Dynamic_Unit_Test {
    /// @dev it should return a zeroed out range.
    function test_GetRange_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupDynamic.Range memory actualRange = dynamic.getRange(nullStreamId);
        LockupDynamic.Range memory expectedRange = LockupDynamic.Range(0, 0);
        assertEq(actualRange, expectedRange);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the correct range.
    function test_GetRange() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Range memory actualRange = dynamic.getRange(streamId);
        LockupDynamic.Range memory expectedRange = DEFAULT_DYNAMIC_RANGE;
        assertEq(actualRange, expectedRange);
    }
}
