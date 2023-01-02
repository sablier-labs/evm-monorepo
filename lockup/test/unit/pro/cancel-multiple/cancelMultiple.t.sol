// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { CancelMultiple__Test } from "test/unit/shared/cancel-multiple/cancelMultiple.t.sol";
import { ProTest } from "test/unit/pro/ProTest.t.sol";

contract CancelMultiple__Pro__Test is ProTest, CancelMultiple__Test {
    function setUp() public virtual override(ProTest, CancelMultiple__Test) {
        CancelMultiple__Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
