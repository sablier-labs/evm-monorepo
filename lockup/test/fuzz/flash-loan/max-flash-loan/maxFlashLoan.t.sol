// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { FlashLoan_Fuzz_Test } from "../FlashLoan.t.sol";

contract MaxFlashLoan_Fuzz_Test is FlashLoan_Fuzz_Test {
    modifier whenAssetFlashLoanable() {
        _;
    }

    function testFuzz_MaxFlashLoan(uint256 dealAmount) external whenAssetFlashLoanable {
        deal({ token: address(dai), to: address(flashLoan), give: dealAmount });
        uint256 actualAmount = flashLoan.maxFlashLoan(address(dai));
        uint256 expectedAmount = dealAmount;
        assertEq(actualAmount, expectedAmount, "maxFlashLoan amount");
    }
}
