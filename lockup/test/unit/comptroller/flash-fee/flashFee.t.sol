// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Comptroller_Test } from "../Comptroller.t.sol";

contract FlashFee_Test is Comptroller_Test {
    function setUp() public override {
        Comptroller_Test.setUp();
    }

    /// @dev it should return zero.
    function test_FlashFee_Zero() external {
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = ZERO;
        assertEq(actualFlashFee, expectedFlashFee);
    }

    /// @dev it should return the correct flash fee.
    function testFuzz_FlashFee(UD60x18 flashFee) external {
        flashFee = bound(flashFee, 1, DEFAULT_MAX_FEE);
        comptroller.setFlashFee(flashFee);
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = flashFee;
        assertEq(actualFlashFee, expectedFlashFee);
    }
}
