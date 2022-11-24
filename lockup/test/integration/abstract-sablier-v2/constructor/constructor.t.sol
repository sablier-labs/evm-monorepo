// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { AbstractSablierV2Test } from "../AbstractSablierV2Test.t.sol";

contract AbstractSablierV2__Test is AbstractSablierV2Test {
    function testConstructor() external {
        assertEq(abstractSablierV2.nextStreamId(), 1);
    }
}
