// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { Cancel__Test } from "test/unit/shared/cancel/Cancel.t.sol";
import { LinearTest } from "test/unit/linear/LinearTest.t.sol";

contract Cancel__Linear__Test is LinearTest, Cancel__Test {
    function setUp() public virtual override(LinearTest, Cancel__Test) {
        Cancel__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
