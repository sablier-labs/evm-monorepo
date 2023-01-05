// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { GetSender__Test } from "test/unit/sablier-v2/shared/get-sender/getSender.t.sol";
import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract GetSender__LinearTest is LinearTest, GetSender__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
