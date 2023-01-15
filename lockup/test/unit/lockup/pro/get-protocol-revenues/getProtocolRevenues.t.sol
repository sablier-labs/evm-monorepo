// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Pro_Test } from "test/unit/lockup/pro/Pro.t.sol";
import { GetProtocolRevenues_Test } from "test/unit/lockup/shared/get-protocol-revenues/getProtocolRevenues.t.sol";
import { Unit_Test } from "test/unit/Unit.t.sol";

contract GetProtocolRevenues_Pro_Test is Pro_Test, GetProtocolRevenues_Test {
    function setUp() public virtual override(Unit_Test, Pro_Test) {
        Pro_Test.setUp();
        sablierV2 = ISablierV2Lockup(pro);
    }
}
