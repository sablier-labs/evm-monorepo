// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { Withdraw_Test } from "test/unit/sablier-v2/shared/withdraw/withdraw.t.sol";

contract Withdraw_LinearTest is LinearTest, Withdraw_Test {
    function setUp() public virtual override(LinearTest, Withdraw_Test) {
        Withdraw_Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
