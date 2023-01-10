// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { IsCancelable__Test } from "test/unit/sablier-v2/shared/is-cancelable/isCancelable.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract IsCancelable__LinearTest is LinearTest, IsCancelable__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
