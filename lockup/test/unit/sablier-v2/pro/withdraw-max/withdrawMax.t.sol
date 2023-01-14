// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { WithdrawMax_Test } from "test/unit/sablier-v2/shared/withdraw-max/withdrawMax.t.sol";

contract WithdrawMax_ProTest is ProTest, WithdrawMax_Test {
    function setUp() public virtual override(ProTest, WithdrawMax_Test) {
        WithdrawMax_Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
