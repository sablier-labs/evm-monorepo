// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { CancelMultiple__Test } from "test/unit/sablier-v2/shared/cancel-multiple/cancelMultiple.t.sol";

contract CancelMultiple__ProTest is ProTest, CancelMultiple__Test {
    function setUp() public virtual override(ProTest, CancelMultiple__Test) {
        CancelMultiple__Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
