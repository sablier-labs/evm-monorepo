// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Linear_Test } from "test/unit/lockup/linear/Linear.t.sol";
import { WithdrawMax_Test } from "test/unit/lockup/shared/withdraw-max/withdrawMax.t.sol";

contract WithdrawMax_Linear_Test is Linear_Test, WithdrawMax_Test {
    function setUp() public virtual override(Linear_Test, WithdrawMax_Test) {
        WithdrawMax_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
