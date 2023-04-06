// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract FlashFee_Unit_Test is Comptroller_Unit_Test {
    function setUp() public override {
        Comptroller_Unit_Test.setUp();
    }

    function test_FlashFee_Zero() external {
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = ZERO;
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }

    function test_FlashFee() external {
        comptroller.setFlashFee(DEFAULT_FLASH_FEE);
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = DEFAULT_FLASH_FEE;
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }
}
