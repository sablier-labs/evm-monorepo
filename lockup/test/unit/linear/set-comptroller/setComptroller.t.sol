// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/linear/LinearTest.t.sol";
import { SetComptroller__Test } from "test/unit/shared/set-comptroller/setComptroller.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract SetComptroller__Linear__Test is LinearTest, SetComptroller__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        super.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
