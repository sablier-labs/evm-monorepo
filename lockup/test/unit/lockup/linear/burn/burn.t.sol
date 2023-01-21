// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Burn_Unit_Test } from "test/unit/lockup/shared/burn/burn.t.sol";
import { Linear_Unit_Test } from "test/unit/lockup/linear/Linear.t.sol";

contract Burn_Linear_Unit_Test is Linear_Unit_Test, Burn_Unit_Test {
    function setUp() public virtual override(Linear_Unit_Test, Burn_Unit_Test) {
        Burn_Unit_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
