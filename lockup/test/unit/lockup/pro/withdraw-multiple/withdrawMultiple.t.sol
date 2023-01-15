// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Pro_Test } from "test/unit/lockup/pro/Pro.t.sol";
import { WithdrawMultiple_Test } from "test/unit/lockup/shared/withdraw-multiple/withdrawMultiple.t.sol";

contract WithdrawMultiple_Pro_Test is Pro_Test, WithdrawMultiple_Test {
    function setUp() public virtual override(Pro_Test, WithdrawMultiple_Test) {
        WithdrawMultiple_Test.setUp();
        lockup = ISablierV2Lockup(pro);
    }
}
