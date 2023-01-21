// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Pro_Unit_Test } from "test/unit/lockup/pro/Pro.t.sol";
import { Renounce_Unit_Test } from "test/unit/lockup/shared/renounce/renounce.t.sol";

contract Renounce_Pro_Unit_Test is Pro_Unit_Test, Renounce_Unit_Test {
    function setUp() public virtual override(Pro_Unit_Test, Renounce_Unit_Test) {
        Renounce_Unit_Test.setUp();
        lockup = ISablierV2Lockup(pro);
    }
}
