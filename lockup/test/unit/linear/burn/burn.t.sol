// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { Burn__Test } from "test/unit/shared/burn/Burn.t.sol";
import { LinearTest } from "test/unit/linear/LinearTest.t.sol";

contract Burn__Linear__Test is LinearTest, Burn__Test {
    function setUp() public virtual override(LinearTest, Burn__Test) {
        Burn__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
