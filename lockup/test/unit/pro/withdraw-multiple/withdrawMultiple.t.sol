// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { WithdrawMultiple__Test } from "test/unit/shared/withdraw-multiple/withdrawMultiple.t.sol";
import { ProTest } from "test/unit/pro/ProTest.t.sol";

contract WithdrawMultiple__ProTest is ProTest, WithdrawMultiple__Test {
    function setUp() public virtual override(ProTest, WithdrawMultiple__Test) {
        WithdrawMultiple__Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
