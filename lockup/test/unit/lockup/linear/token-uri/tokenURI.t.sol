// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Linear_Test } from "test/unit/lockup/linear/Linear.t.sol";
import { TokenURI_Test } from "test/unit/lockup/shared/token-uri/tokenURI.t.sol";
import { Unit_Test } from "test/unit/Unit.t.sol";

contract TokenURI_Linear_Test is Linear_Test, TokenURI_Test {
    function setUp() public virtual override(Unit_Test, Linear_Test) {
        Linear_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
