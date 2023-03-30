// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { FlashLoan_Fuzz_Test } from "../FlashLoan.t.sol";

contract FlashFee_Fuzz_Test is FlashLoan_Fuzz_Test {
    /// @dev it should return the correct flash fee.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the comptroller flash fee, including zero.
    /// - Multiple values for the flash loan amount, including zero.
    function testFuzz_FlashFee(UD60x18 comptrollerFlashFee, uint256 amount) external {
        comptrollerFlashFee = bound(comptrollerFlashFee, 0, MAX_FEE);
        comptroller.setFlashFee(comptrollerFlashFee);
        uint256 actualFlashFee = flashLoan.flashFee({ asset: address(DEFAULT_ASSET), amount: amount });
        uint256 expectedFlashFee = ud(amount).mul(comptrollerFlashFee).intoUint256();
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }
}
