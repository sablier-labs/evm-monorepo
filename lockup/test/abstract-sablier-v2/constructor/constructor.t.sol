// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { AbstractSablierV2BaseTest } from "../AbstractSablierV2BaseTest.t.sol";

contract AbstractSablierV2Test is AbstractSablierV2BaseTest {
    function testConstructor() external {
        assertEq(abstractSablierV2.nextStreamId(), 1);
    }
}
