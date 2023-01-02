// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { GetWithdrawnAmount__Test } from "test/unit/shared/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { LinearTest } from "test/unit/linear/LinearTest.t.sol";

contract GetWithdrawnAmount__Linear__Test is LinearTest, GetWithdrawnAmount__Test {
    function setUp() public virtual override(LinearTest, GetWithdrawnAmount__Test) {
        GetWithdrawnAmount__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
