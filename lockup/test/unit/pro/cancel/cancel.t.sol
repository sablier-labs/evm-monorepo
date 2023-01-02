// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { Cancel__Test } from "test/unit/shared/cancel/Cancel.t.sol";
import { ProTest } from "test/unit/pro/ProTest.t.sol";

contract Cancel__Pro__Test is ProTest, Cancel__Test {
    function setUp() public virtual override(ProTest, Cancel__Test) {
        Cancel__Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
