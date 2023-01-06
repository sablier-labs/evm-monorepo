// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { Withdraw_Test } from "test/unit/sablier-v2/shared/withdraw/withdraw.t.sol";

contract Withdraw_ProTest is ProTest, Withdraw_Test {
    function setUp() public virtual override(ProTest, Withdraw_Test) {
        Withdraw_Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
