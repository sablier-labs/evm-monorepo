// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { IsCancelable__Test } from "test/unit/shared/is-cancelable/isCancelable.t.sol";
import { ProTest } from "test/unit/pro/ProTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract IsCancelable__Pro__Test is ProTest, IsCancelable__Test {
    function setUp() public virtual override(UnitTest, ProTest) {
        ProTest.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
