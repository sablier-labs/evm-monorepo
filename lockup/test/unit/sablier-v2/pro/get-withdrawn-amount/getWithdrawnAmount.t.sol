// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { GetWithdrawnAmount_Test } from "test/unit/sablier-v2/shared/get-withdrawn-amount/getWithdrawnAmount.t.sol";

contract GetWithdrawnAmount_ProTest is ProTest, GetWithdrawnAmount_Test {
    function setUp() public virtual override(ProTest, GetWithdrawnAmount_Test) {
        GetWithdrawnAmount_Test.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
