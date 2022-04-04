// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";
import { SablierV2UnitTest } from "../SablierV2UnitTest.t.sol";

contract SablierV2LinearTest is SablierV2UnitTest {
    function testConstructor() external {
        assertEq(sablierV2Linear.nextStreamId(), 1);
    }
}
