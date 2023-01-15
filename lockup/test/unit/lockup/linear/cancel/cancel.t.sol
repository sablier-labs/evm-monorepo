// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Cancel_Test } from "test/unit/lockup/shared/cancel/cancel.t.sol";
import { Linear_Test } from "test/unit/lockup/linear/Linear.t.sol";

contract Cancel_Linear_Test is Linear_Test, Cancel_Test {
    function setUp() public virtual override(Linear_Test, Cancel_Test) {
        Cancel_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
