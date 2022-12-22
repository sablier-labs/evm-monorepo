// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { LinearTest } from "../LinearTest.t.sol";

contract Constructor__Test is LinearTest {
    function testConstructor() external {
        uint256 actualStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId);
    }
}
