// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { FlashLoan_Integration_Shared_Test } from "../../shared/flash-loan/FlashLoan.t.sol";

contract MaxFlashLoan_Integration_Fuzz_Test is FlashLoan_Integration_Shared_Test {
    modifier whenAssetFlashLoanable() {
        comptroller.toggleFlashAsset(dai);
        _;
    }

    function testFuzz_MaxFlashLoan(uint256 dealAmount) external whenAssetFlashLoanable {
        deal({ token: address(dai), to: address(flashLoan), give: dealAmount });
        uint256 actualAmount = flashLoan.maxFlashLoan(address(dai));
        uint256 expectedAmount = dealAmount;
        assertEq(actualAmount, expectedAmount, "maxFlashLoan amount");
    }
}
