// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { GetRecipient__Test } from "test/unit/sablier-v2/shared/get-recipient/getRecipient.t.sol";
import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract GetRecipient__LinearTest is LinearTest, GetRecipient__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
