// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract Constructor__Test is SablierV2ProTest {
    function testConstructor() external {
        uint256 actualStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId);

        uint256 actualMaxSegmentCount = sablierV2Pro.MAX_SEGMENT_COUNT();
        uint256 expectedMaxSegmentCount = MAX_SEGMENT_COUNT;
        assertEq(actualMaxSegmentCount, expectedMaxSegmentCount);
    }
}
