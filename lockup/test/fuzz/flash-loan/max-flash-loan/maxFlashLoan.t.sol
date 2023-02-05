// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { FlashLoan_Fuzz_Test } from "../FlashLoan.t.sol";

contract MaxFlashLoan_Fuzz_Test is FlashLoan_Fuzz_Test {
    /// @dev it should return the correct flash fee.
    function testFuzz_MaxFlashLoan(uint256 dealAmount) external {
        deal({ token: address(DEFAULT_ASSET), to: address(flashLoan), give: dealAmount });
        uint256 actualAmount = flashLoan.maxFlashLoan(address(DEFAULT_ASSET));
        uint256 expectedAmount = dealAmount;
        assertEq(actualAmount, expectedAmount, "maxFlashLoan amount");
    }
}
