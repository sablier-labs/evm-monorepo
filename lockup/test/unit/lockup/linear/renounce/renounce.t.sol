// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Linear_Unit_Test } from "test/unit/lockup/linear/Linear.t.sol";
import { Renounce_Unit_Test } from "test/unit/lockup/shared/renounce/renounce.t.sol";

contract Renounce_Linear_Unit_Test is Linear_Unit_Test, Renounce_Unit_Test {
    function setUp() public virtual override(Linear_Unit_Test, Renounce_Unit_Test) {
        Renounce_Unit_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
