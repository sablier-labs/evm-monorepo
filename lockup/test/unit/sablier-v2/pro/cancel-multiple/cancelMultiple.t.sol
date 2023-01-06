// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { CancelMultiple_Test } from "test/unit/sablier-v2/shared/cancel-multiple/cancelMultiple.t.sol";

contract CancelMultiple_ProTest is ProTest, CancelMultiple_Test {
    function setUp() public virtual override(ProTest, CancelMultiple_Test) {
        CancelMultiple_Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
