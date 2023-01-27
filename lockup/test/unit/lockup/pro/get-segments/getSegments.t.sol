// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Segment } from "src/types/Structs.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract GetSegments_Pro_Unit_Test is Pro_Unit_Test {
    /// @dev it should return an empty array.
    function test_GetSegments_StreamNull() external {
        uint256 nullStreamId = 1729;
        Segment[] memory actualSegments = pro.getSegments(nullStreamId);
        Segment[] memory expectedSegments;
        assertEq(actualSegments, expectedSegments, "segments");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct segments.
    function test_GetSegments() external streamNonNull {
        uint256 streamId = createDefaultStream();
        Segment[] memory actualSegments = pro.getSegments(streamId);
        Segment[] memory expectedSegments = DEFAULT_SEGMENTS;
        assertEq(actualSegments, expectedSegments, "segments");
    }
}
