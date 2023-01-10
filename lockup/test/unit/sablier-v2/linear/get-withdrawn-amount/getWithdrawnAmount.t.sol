// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { GetWithdrawnAmount__Test } from "test/unit/sablier-v2/shared/get-withdrawn-amount/getWithdrawnAmount.t.sol";

contract GetWithdrawnAmount__LinearTest is LinearTest, GetWithdrawnAmount__Test {
    function setUp() public virtual override(LinearTest, GetWithdrawnAmount__Test) {
        GetWithdrawnAmount__Test.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
