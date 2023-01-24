// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import {
    ClaimProtocolRevenues_Test
} from "test/unit/lockup/shared/claim-protocol-revenues/claimProtocolRevenues.t.sol";
import { Linear_Test } from "test/unit/lockup/linear/Linear.t.sol";
import { Unit_Test } from "test/unit/Unit.t.sol";

contract ClaimProtocolRevenues_Linear_Test is Linear_Test, ClaimProtocolRevenues_Test {
    function setUp() public virtual override(Unit_Test, Linear_Test) {
        Linear_Test.setUp();
        sablierV2 = ISablierV2Lockup(linear);
    }
}
