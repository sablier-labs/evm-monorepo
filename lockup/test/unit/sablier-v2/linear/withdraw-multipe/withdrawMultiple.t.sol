// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { WithdrawMultiple__Test } from "test/unit/sablier-v2/shared/withdraw-multiple/withdrawMultiple.t.sol";

contract WithdrawMultiple__LinearTest is LinearTest, WithdrawMultiple__Test {
    function setUp() public virtual override(LinearTest, WithdrawMultiple__Test) {
        WithdrawMultiple__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
