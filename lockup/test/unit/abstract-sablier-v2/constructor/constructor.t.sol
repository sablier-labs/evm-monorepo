// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";
import { AbstractSablierV2UnitTest } from "../AbstractSablierV2UnitTest.t.sol";

contract AbstractSablierV2Test is AbstractSablierV2UnitTest {
    function testConstructor() external {
        assertEq(abstractSablierV2.nextStreamId(), 1);
    }
}
