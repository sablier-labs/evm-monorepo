// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract Constructor__ProTest is ProTest {
    function testConstructor() external {
        uint256 actualStreamId = pro.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId);

        uint256 actualMaxSegmentCount = pro.MAX_SEGMENT_COUNT();
        uint256 expectedMaxSegmentCount = DEFAULT_MAX_SEGMENT_COUNT;
        assertEq(actualMaxSegmentCount, expectedMaxSegmentCount);
    }
}
