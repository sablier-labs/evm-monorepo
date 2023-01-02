// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { GetWithdrawnAmount__Test } from "test/unit/shared/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { ProTest } from "test/unit/pro/ProTest.t.sol";

contract GetWithdrawnAmount__ProTest is ProTest, GetWithdrawnAmount__Test {
    function setUp() public virtual override(ProTest, GetWithdrawnAmount__Test) {
        GetWithdrawnAmount__Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
