// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Linear_Test } from "../Linear.t.sol";

contract Constructor_Linear_Test is Linear_Test {
    function test_Constructor() external {
        uint256 actualStreamId = linear.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "streamId");
    }
}
