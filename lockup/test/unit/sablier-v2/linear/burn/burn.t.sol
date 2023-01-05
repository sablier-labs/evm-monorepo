// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { Burn__Test } from "test/unit/sablier-v2/shared/burn/burn.t.sol";
import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";

contract Burn__LinearTest is LinearTest, Burn__Test {
    function setUp() public virtual override(LinearTest, Burn__Test) {
        Burn__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
