// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { ProTest } from "test/unit/sablier-v2/pro/ProTest.t.sol";
import { GetProtocolRevenues_Test } from "test/unit/sablier-v2/shared/get-protocol-revenues/getProtocolRevenues.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract GetProtocolRevenues_ProTest is ProTest, GetProtocolRevenues_Test {
    function setUp() public virtual override(UnitTest, ProTest) {
        ProTest.setUp();
        sablierV2 = ISablierV2(pro);
    }
}
