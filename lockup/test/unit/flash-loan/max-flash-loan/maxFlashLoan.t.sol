// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { FlashLoan_Unit_Test } from "../FlashLoan.t.sol";

contract MaxFlashLoan_Unit_Test is FlashLoan_Unit_Test {
    function test_MaxFlashLoan_AssetNotFlashLoanable() external {
        uint256 actualAmount = flashLoan.maxFlashLoan(address(usdc));
        uint256 expectedAmount = 0;
        assertEq(actualAmount, expectedAmount, "maxFlashLoan amount");
    }

    modifier whenAssetFlashLoanable() {
        comptroller.toggleFlashAsset(usdc);
        _;
    }

    function test_MaxFlashLoan() external whenAssetFlashLoanable {
        uint256 dealAmount = 14_607_904e18;
        deal({ token: address(usdc), to: address(flashLoan), give: dealAmount });
        uint256 actualAmount = flashLoan.maxFlashLoan(address(usdc));
        uint256 expectedAmount = dealAmount;
        assertEq(actualAmount, expectedAmount, "maxFlashLoan amount");
    }
}
