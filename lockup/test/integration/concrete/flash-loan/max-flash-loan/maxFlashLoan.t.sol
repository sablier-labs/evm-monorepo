// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { FlashLoan_Integration_Shared_Test } from "../../../shared/flash-loan/FlashLoan.t.sol";

contract MaxFlashLoan_Integration_Concrete_Test is FlashLoan_Integration_Shared_Test {
    function test_MaxFlashLoan_AssetNotFlashLoanable() external {
        uint256 actualAmount = flashLoan.maxFlashLoan(address(dai));
        uint256 expectedAmount = 0;
        assertEq(actualAmount, expectedAmount, "maxFlashLoan amount");
    }

    modifier whenAssetFlashLoanable() {
        comptroller.toggleFlashAsset(dai);
        _;
    }

    function test_MaxFlashLoan() external whenAssetFlashLoanable {
        uint256 dealAmount = 14_607_904e18;
        deal({ token: address(dai), to: address(flashLoan), give: dealAmount });
        uint256 actualAmount = flashLoan.maxFlashLoan(address(dai));
        uint256 expectedAmount = dealAmount;
        assertEq(actualAmount, expectedAmount, "maxFlashLoan amount");
    }
}
