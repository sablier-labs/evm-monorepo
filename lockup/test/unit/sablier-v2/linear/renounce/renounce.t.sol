// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { Renounce_Test } from "test/unit/sablier-v2/shared/renounce/renounce.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract Renounce_LinearTest is LinearTest, Renounce_Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
