// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { Cancel_Test } from "test/unit/sablier-v2/shared/cancel/cancel.t.sol";

contract Cancel_ProTest is ProTest, Cancel_Test {
    function setUp() public virtual override(ProTest, Cancel_Test) {
        Cancel_Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
