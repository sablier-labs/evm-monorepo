// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { FlashLoan_Test } from "../FlashLoan.t.sol";

contract FlashFee_Test is FlashLoan_Test {
    address internal asset = address(dai);

    function setUp() public override {
        FlashLoan_Test.setUp();
    }

    /// @dev it should revert.
    function test_RevertWhen_AssetNotFlashLoanable() external {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2FlashLoan_AssetNotFlashLoanable.selector, IERC20(asset))
        );
        flashLoan.flashFee({ asset: asset, amount: 0 });
    }

    modifier assetFlashLoanable() {
        comptroller.toggleFlashAsset(IERC20(asset));
        _;
    }

    /// @dev it should return the correct flash fee.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the comptroller flash fee, including zero.
    /// - Multiple values for the flash loan amount, including zero.
    function testFuzz_FlashFee(UD60x18 comptrollerFlashFee, uint256 amount) external assetFlashLoanable {
        comptrollerFlashFee = bound(comptrollerFlashFee, 0, DEFAULT_MAX_FEE);
        comptroller.setFlashFee(comptrollerFlashFee);
        uint256 actualFee = flashLoan.flashFee(asset, amount);
        uint256 expectedFee = ud(amount).mul(comptrollerFlashFee).intoUint256();
        assertEq(actualFee, expectedFee);
    }
}
