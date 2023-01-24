// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Burn_Test } from "test/unit/lockup/shared/burn/burn.t.sol";
import { Linear_Test } from "test/unit/lockup/linear/Linear.t.sol";

contract Burn_Linear_Test is Linear_Test, Burn_Test {
    function setUp() public virtual override(Linear_Test, Burn_Test) {
        Burn_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
