// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract GetSegments_Dynamic_Unit_Test is Dynamic_Unit_Test {
    /// @dev it should return an empty array.
    function test_GetSegments_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupDynamic.Segment[] memory actualSegments = dynamic.getSegments(nullStreamId);
        LockupDynamic.Segment[] memory expectedSegments;
        assertEq(actualSegments, expectedSegments, "segments");
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the correct segments.
    function test_GetSegments() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Segment[] memory actualSegments = dynamic.getSegments(streamId);
        LockupDynamic.Segment[] memory expectedSegments = DEFAULT_SEGMENTS;
        assertEq(actualSegments, expectedSegments, "segments");
    }
}
