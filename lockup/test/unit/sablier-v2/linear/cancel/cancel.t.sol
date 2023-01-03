// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { Cancel__Test } from "test/unit/sablier-v2/shared/cancel/cancel.t.sol";
import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";

contract Cancel__LinearTest is LinearTest, Cancel__Test {
    function setUp() public virtual override(LinearTest, Cancel__Test) {
        Cancel__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
