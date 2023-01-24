// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { IsCancelable_Test } from "test/unit/sablier-v2/shared/is-cancelable/isCancelable.t.sol";

contract IsCancelable_LinearTest is LinearTest, IsCancelable_Test {
    function setUp() public virtual override(LinearTest, IsCancelable_Test) {
        IsCancelable_Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
