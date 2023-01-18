// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { FlashLoan_Test } from "../FlashLoan.t.sol";

contract MaxFlashLoan_Test is FlashLoan_Test {
    address internal asset = address(dai);

    function setUp() public override {
        FlashLoan_Test.setUp();
    }

    /// @dev it should revert.
    function test_MaxFlashLoan_AssetNotFlashLoanable() external {
        uint256 actualAmount = flashLoan.maxFlashLoan(asset);
        uint256 expectedAmount = 0;
        assertEq(actualAmount, expectedAmount);
    }

    modifier assetFlashLoanable() {
        comptroller.toggleFlashAsset(IERC20(asset));
        _;
    }

    /// @dev it should return the correct flash fee.
    function testFuzz_MaxFlashLoan(uint256 dealAmount) external assetFlashLoanable {
        deal({ token: asset, to: address(flashLoan), give: dealAmount });
        uint256 actualAmount = flashLoan.maxFlashLoan(asset);
        uint256 expectedAmount = dealAmount;
        assertEq(actualAmount, expectedAmount);
    }
}
