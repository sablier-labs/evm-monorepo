// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { GetProtocolRevenues__Test } from "test/unit/shared/get-protocol-revenues/getProtocolRevenues.t.sol";
import { ProTest } from "test/unit/pro/ProTest.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract GetProtocolRevenues__Pro__Test is ProTest, GetProtocolRevenues__Test {
    function setUp() public virtual override(UnitTest, ProTest) {
        ProTest.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
