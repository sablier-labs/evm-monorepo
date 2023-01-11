// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ProTest } from "../ProTest.t.sol";

contract Constructor_ProTest is ProTest {
    function testConstructor() external {
        uint256 actualStreamId = pro.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId);

        uint256 actualMaxSegmentCount = pro.MAX_SEGMENT_COUNT();
        uint256 expectedMaxSegmentCount = DEFAULT_MAX_SEGMENT_COUNT;
        assertEq(actualMaxSegmentCount, expectedMaxSegmentCount);
    }
}
