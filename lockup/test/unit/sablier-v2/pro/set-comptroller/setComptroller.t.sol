// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { SetComptroller__Test } from "test/unit/sablier-v2/shared/set-comptroller/setComptroller.t.sol";
import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract SetComptroller__ProTest is ProTest, SetComptroller__Test {
    function setUp() public virtual override(UnitTest, ProTest) {
        ProTest.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
