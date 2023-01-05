// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { Withdraw__Test } from "test/unit/sablier-v2/shared/withdraw/withdraw.t.sol";
import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";

contract Withdraw__LinearTest is LinearTest, Withdraw__Test {
    function setUp() public virtual override(LinearTest, Withdraw__Test) {
        Withdraw__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
