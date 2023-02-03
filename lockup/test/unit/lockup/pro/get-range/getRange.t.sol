// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { LockupPro } from "src/types/DataTypes.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract GetRange_Pro_Unit_Test is Pro_Unit_Test {
    /// @dev it should return a zeroed out range.
    function test_GetRange_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupPro.Range memory actualRange = pro.getRange(nullStreamId);
        LockupPro.Range memory expectedRange = LockupPro.Range(0, 0);
        assertEq(actualRange, expectedRange);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct range.
    function test_GetRange() external streamNonNull {
        uint256 streamId = createDefaultStream();
        LockupPro.Range memory actualRange = pro.getRange(streamId);
        LockupPro.Range memory expectedRange = DEFAULT_PRO_RANGE;
        assertEq(actualRange, expectedRange);
    }
}
