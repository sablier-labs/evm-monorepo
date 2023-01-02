// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { CancelMultiple__Test } from "test/unit/shared/cancel-multiple/cancelMultiple.t.sol";
import { LinearTest } from "test/unit/linear/LinearTest.t.sol";

contract CancelMultiple__LinearTest is LinearTest, CancelMultiple__Test {
    function setUp() public virtual override(LinearTest, CancelMultiple__Test) {
        CancelMultiple__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
