// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Burn_Test } from "test/unit/lockup/shared/burn/burn.t.sol";
import { Pro_Test } from "test/unit/lockup/pro/Pro.t.sol";

contract Burn_Pro_Test is Pro_Test, Burn_Test {
    function setUp() public virtual override(Pro_Test, Burn_Test) {
        Burn_Test.setUp();
        lockup = ISablierV2Lockup(pro);
    }
}
