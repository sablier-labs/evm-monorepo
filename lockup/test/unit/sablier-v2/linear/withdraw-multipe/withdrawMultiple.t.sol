// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { WithdrawMultiple_Test } from "test/unit/sablier-v2/shared/withdraw-multiple/withdrawMultiple.t.sol";

contract WithdrawMultiple_LinearTest is LinearTest, WithdrawMultiple_Test {
    function setUp() public virtual override(LinearTest, WithdrawMultiple_Test) {
        WithdrawMultiple_Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
