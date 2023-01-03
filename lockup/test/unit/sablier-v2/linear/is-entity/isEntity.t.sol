// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { IsEntity__Test } from "test/unit/sablier-v2/shared/is-entity/isEntity.t.sol";
import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract IsEntity__LinearTest is LinearTest, IsEntity__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
