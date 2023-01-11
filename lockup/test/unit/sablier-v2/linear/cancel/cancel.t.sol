// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { Cancel_Test } from "test/unit/sablier-v2/shared/cancel/cancel.t.sol";
import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";

contract Cancel_LinearTest is LinearTest, Cancel_Test {
    function setUp() public virtual override(LinearTest, Cancel_Test) {
        Cancel_Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
