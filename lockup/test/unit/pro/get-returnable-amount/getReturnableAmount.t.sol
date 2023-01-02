// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { GetReturnableAmount__Test } from "test/unit/shared/get-returnable-amount/getReturnableAmount.t.sol";
import { ProTest } from "test/unit/pro/ProTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract GetReturnableAmount__ProTest is ProTest, GetReturnableAmount__Test {
    function setUp() public virtual override(UnitTest, ProTest) {
        ProTest.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
