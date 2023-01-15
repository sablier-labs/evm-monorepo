// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { CancelMultiple_Test } from "test/unit/lockup/shared/cancel-multiple/cancelMultiple.t.sol";
import { Linear_Test } from "test/unit/lockup/linear/Linear.t.sol";

contract CancelMultiple_Linear_Test is Linear_Test, CancelMultiple_Test {
    function setUp() public virtual override(Linear_Test, CancelMultiple_Test) {
        CancelMultiple_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
