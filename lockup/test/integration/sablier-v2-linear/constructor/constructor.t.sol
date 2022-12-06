// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract Constructor__Test is SablierV2LinearTest {
    function testConstructor() external {
        uint256 actualStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId);
    }
}
