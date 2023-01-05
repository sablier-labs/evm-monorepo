// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { SetComptroller__Test } from "test/unit/sablier-v2/shared/set-comptroller/setComptroller.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract SetComptroller__LinearTest is LinearTest, SetComptroller__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
