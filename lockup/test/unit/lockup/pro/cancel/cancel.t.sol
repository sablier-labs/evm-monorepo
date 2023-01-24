// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Pro_Test } from "test/unit/lockup/pro/Pro.t.sol";
import { Cancel_Test } from "test/unit/lockup/shared/cancel/cancel.t.sol";

contract Cancel_Pro_Test is Pro_Test, Cancel_Test {
    function setUp() public virtual override(Pro_Test, Cancel_Test) {
        Cancel_Test.setUp();
        lockup = ISablierV2Lockup(pro);
    }
}
