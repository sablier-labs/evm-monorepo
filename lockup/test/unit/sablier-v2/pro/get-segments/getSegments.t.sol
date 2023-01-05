// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Segment } from "src/types/Structs.sol";

import { ProTest } from "../ProTest.t.sol";

contract GetSegments__ProTest is ProTest {
    /// @dev it should return an empty array.
    function testGetSegments__StreamNonExistents() external {
        uint256 nonStreamId = 1729;
        Segment[] memory actualSegments = pro.getSegments(nonStreamId);
        Segment[] memory expectedSegments;
        assertEq(actualSegments, expectedSegments);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segments.
    function testGetSegments() external StreamExistent {
        uint256 streamId = createDefaultStream();
        Segment[] memory actualSegments = pro.getSegments(streamId);
        Segment[] memory expectedSegments = DEFAULT_SEGMENTS;
        assertEq(actualSegments, expectedSegments);
    }
}
