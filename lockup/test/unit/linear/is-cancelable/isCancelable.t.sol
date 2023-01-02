// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { IsCancelable__Test } from "test/unit/shared/is-cancelable/isCancelable.t.sol";
import { LinearTest } from "test/unit/linear/LinearTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract IsCancelable__LinearTest is LinearTest, IsCancelable__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
