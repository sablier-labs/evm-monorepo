// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Pro_Test } from "test/unit/lockup/pro/Pro.t.sol";
import { Renounce_Test } from "test/unit/lockup/shared/renounce/renounce.t.sol";

contract Renounce_Pro_Test is Pro_Test, Renounce_Test {
    function setUp() public virtual override(Pro_Test, Renounce_Test) {
        Renounce_Test.setUp();
        lockup = ISablierV2Lockup(pro);
    }
}
