// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { IsCancelable_Test } from "test/unit/sablier-v2/shared/is-cancelable/isCancelable.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract IsCancelable_ProTest is ProTest, IsCancelable_Test {
    function setUp() public virtual override(UnitTest, ProTest) {
        ProTest.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
