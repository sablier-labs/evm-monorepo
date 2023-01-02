// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/linear/LinearTest.t.sol";
import { Renounce__Test } from "test/unit/shared/renounce/renounce.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract Renounce__LinearTest is LinearTest, Renounce__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
