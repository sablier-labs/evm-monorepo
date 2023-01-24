// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Linear_Test } from "test/unit/lockup/linear/Linear.t.sol";
import { IsCancelable_Test } from "test/unit/lockup/shared/is-cancelable/isCancelable.t.sol";

contract IsCancelable_Linear_Test is Linear_Test, IsCancelable_Test {
    function setUp() public virtual override(Linear_Test, IsCancelable_Test) {
        IsCancelable_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
