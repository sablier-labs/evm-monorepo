// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { LinearTest } from "../LinearTest.t.sol";

contract Constructor_LinearTest is LinearTest {
    function testConstructor() external {
        uint256 actualStreamId = linear.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId);
    }
}
