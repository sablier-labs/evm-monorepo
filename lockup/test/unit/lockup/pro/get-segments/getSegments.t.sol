// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupPro } from "src/types/DataTypes.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract GetSegments_Pro_Unit_Test is Pro_Unit_Test {
    /// @dev it should return an empty array.
    function test_GetSegments_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupPro.Segment[] memory actualSegments = pro.getSegments(nullStreamId);
        LockupPro.Segment[] memory expectedSegments;
        assertEq(actualSegments, expectedSegments, "segments");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct segments.
    function test_GetSegments() external streamNonNull {
        uint256 streamId = createDefaultStream();
        LockupPro.Segment[] memory actualSegments = pro.getSegments(streamId);
        LockupPro.Segment[] memory expectedSegments = DEFAULT_SEGMENTS;
        assertEq(actualSegments, expectedSegments, "segments");
    }
}
