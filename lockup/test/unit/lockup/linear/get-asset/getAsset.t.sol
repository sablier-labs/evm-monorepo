// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Linear_Unit_Test } from "test/unit/lockup/linear/Linear.t.sol";
import { GetAsset_Unit_Test } from "test/unit/lockup/shared/get-asset/getAsset.t.sol";
import { Unit_Test } from "test/unit/Unit.t.sol";

contract GetAsset_Linear_Unit_Test is Linear_Unit_Test, GetAsset_Unit_Test {
    function setUp() public virtual override(Unit_Test, Linear_Unit_Test) {
        Linear_Unit_Test.setUp();
        lockup = ISablierV2Lockup(linear);
    }
}
