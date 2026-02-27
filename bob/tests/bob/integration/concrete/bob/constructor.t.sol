// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierBob } from "src/SablierBob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_Bob_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        SablierBob constructedBob = new SablierBob(address(comptroller));

        // {Comptrollerable.constructor}
        assertEq(address(constructedBob.comptroller()), address(comptroller), "comptroller");

        // {SablierBobState.constructor}
        assertEq(constructedBob.nextVaultId(), 1, "nextVaultId");

        // {SablierBob.GRACE_PERIOD}
        assertEq(constructedBob.GRACE_PERIOD(), GRACE_PERIOD, "GRACE_PERIOD");
    }
}
