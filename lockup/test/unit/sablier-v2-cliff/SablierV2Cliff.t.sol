// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { SablierV2Cliff } from "@sablier/v2-core/SablierV2Cliff.sol";
import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2LinearTest is SablierV2CliffUnitTest {
    function testConstructor() external {
        assertEq(sablierV2Cliff.nextStreamId(), 1);
    }
}
