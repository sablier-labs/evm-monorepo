// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { SablierLidoAdapter } from "src/SablierLidoAdapter.sol";

import { Integration_Test } from "../../../Integration.t.sol";

/// @title Constructor_LidoAdapter_Integration_Concrete_Test
/// @notice Integration tests for the SablierLidoAdapter constructor.
contract Constructor_LidoAdapter_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                       TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_SlippageToleranceExceedsMaximum() external {
        // Prepare slippage tolerance that exceeds maximum (5% + 1 wei).
        UD60x18 excessiveSlippage = UD60x18.wrap(MAX_SLIPPAGE_TOLERANCE.unwrap() + 1);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_SlippageToleranceTooHigh.selector,
                excessiveSlippage.unwrap(),
                MAX_SLIPPAGE_TOLERANCE.unwrap()
            )
        );

        // Attempt to deploy with excessive slippage tolerance.
        new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            stETH: address(steth),
            wETH: address(weth),
            wstETH: address(wstEth),
            initialSlippageTolerance: excessiveSlippage,
            initialYieldFee: YIELD_FEE
        });
    }

    function test_RevertWhen_YieldFeeExceedsMaximum() external {
        // Prepare yield fee that exceeds maximum (20% + 1 wei).
        UD60x18 excessiveFee = UD60x18.wrap(MAX_YIELD_FEE.unwrap() + 1);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_YieldFeeTooHigh.selector, excessiveFee.unwrap(), MAX_YIELD_FEE.unwrap()
            )
        );

        // Attempt to deploy with excessive yield fee.
        new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            stETH: address(steth),
            wETH: address(weth),
            wstETH: address(wstEth),
            initialSlippageTolerance: SLIPPAGE_TOLERANCE,
            initialYieldFee: excessiveFee
        });
    }

    function test_WhenParametersAreValid() external {
        // Deploy adapter with valid parameters.
        SablierLidoAdapter newAdapter = new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            stETH: address(steth),
            wETH: address(weth),
            wstETH: address(wstEth),
            initialSlippageTolerance: SLIPPAGE_TOLERANCE,
            initialYieldFee: YIELD_FEE
        });

        // Verify comptroller is set correctly.
        assertEq(address(newAdapter.comptroller()), address(comptroller), "comptroller");

        // Verify SABLIER_BOB is set correctly.
        assertEq(newAdapter.SABLIER_BOB(), address(bob), "SABLIER_BOB");

        // Verify slippage tolerance is set correctly.
        assertEq(newAdapter.slippageTolerance().unwrap(), SLIPPAGE_TOLERANCE.unwrap(), "slippageTolerance");

        // Verify yield fee is set correctly.
        assertEq(newAdapter.feeOnYield().unwrap(), YIELD_FEE.unwrap(), "feeOnYield");
    }
}
