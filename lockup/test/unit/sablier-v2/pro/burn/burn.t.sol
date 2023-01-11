// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { Burn_Test } from "test/unit/sablier-v2/shared/burn/burn.t.sol";
import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";

contract Burn_ProTest is ProTest, Burn_Test {
    function setUp() public virtual override(ProTest, Burn_Test) {
        Burn_Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
