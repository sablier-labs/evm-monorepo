// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Pro_Test } from "test/unit/lockup/pro/Pro.t.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import {
    ClaimProtocolRevenues_Test
} from "test/unit/lockup/shared/claim-protocol-revenues/claimProtocolRevenues.t.sol";
import { Unit_Test } from "test/unit/Unit.t.sol";

contract ClaimProtocolRevenues_Pro_Test is Pro_Test, ClaimProtocolRevenues_Test {
    function setUp() public virtual override(Unit_Test, Pro_Test) {
        Pro_Test.setUp();
        sablierV2 = ISablierV2Lockup(pro);
    }
}
