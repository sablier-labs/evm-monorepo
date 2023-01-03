// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import {
    ClaimProtocolRevenues__Test
} from "test/unit/sablier-v2/shared/claim-protocol-revenues/claimProtocolRevenues.t.sol";
import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract ClaimProtocolRevenues__ProTest is ProTest, ClaimProtocolRevenues__Test {
    function setUp() public virtual override(UnitTest, ProTest) {
        ProTest.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
