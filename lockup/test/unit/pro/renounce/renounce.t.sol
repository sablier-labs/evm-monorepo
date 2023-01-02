// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/pro/ProTest.t.sol";
import { Renounce__Test } from "test/unit/shared/renounce/renounce.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract Renounce__Pro__Test is ProTest, Renounce__Test {
    function setUp() public virtual override(UnitTest, ProTest) {
        ProTest.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
