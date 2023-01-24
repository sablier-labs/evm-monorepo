// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Linear_Test } from "test/unit/lockup/linear/Linear.t.sol";
import { Withdraw_Test } from "test/unit/lockup/shared/withdraw/withdraw.t.sol";

contract Withdraw_Linear_Test is Linear_Test, Withdraw_Test {
    function setUp() public virtual override(Linear_Test, Withdraw_Test) {
        Withdraw_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
