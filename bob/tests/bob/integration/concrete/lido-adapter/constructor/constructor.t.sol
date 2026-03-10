// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { SablierLidoAdapter } from "src/SablierLidoAdapter.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_LidoAdapter_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_SlippageToleranceExceedsMax() external {
        UD60x18 slippageTolerance = MAX_SLIPPAGE_TOLERANCE.add(UNIT);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_SlippageToleranceTooHigh.selector, slippageTolerance, MAX_SLIPPAGE_TOLERANCE
            )
        );

        new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            stETH: address(steth),
            stETH_ETH_Oracle: address(stETHETHOracle),
            wETH: address(weth),
            wstETH: address(wstEth),
            initialSlippageTolerance: slippageTolerance,
            initialYieldFee: YIELD_FEE
        });
    }

    function test_RevertWhen_YieldFeeExceedsMax() external whenSlippageToleranceNotExceedMax {
        UD60x18 yieldFee = MAX_YIELD_FEE.add(UNIT);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_YieldFeeTooHigh.selector, yieldFee, MAX_YIELD_FEE)
        );

        new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            stETH: address(steth),
            stETH_ETH_Oracle: address(stETHETHOracle),
            wETH: address(weth),
            wstETH: address(wstEth),
            initialSlippageTolerance: SLIPPAGE_TOLERANCE,
            initialYieldFee: yieldFee
        });
    }

    function test_WhenYieldFeeNotExceedMax() external whenSlippageToleranceNotExceedMax {
        // Deploy a new adapter.
        adapter = new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            stETH: address(steth),
            stETH_ETH_Oracle: address(stETHETHOracle),
            wETH: address(weth),
            wstETH: address(wstEth),
            initialSlippageTolerance: SLIPPAGE_TOLERANCE,
            initialYieldFee: YIELD_FEE
        });

        // It should set the comptroller.
        assertEq(address(adapter.comptroller()), address(comptroller), "comptroller");

        // It should set immutable state variables.
        assertEq(adapter.SABLIER_BOB(), address(bob), "SABLIER_BOB");
        assertEq(adapter.CURVE_POOL(), address(curvePool), "CURVE_POOL");
        assertEq(adapter.STETH(), address(steth), "STETH");
        assertEq(adapter.WETH(), address(weth), "WETH");
        assertEq(adapter.WSTETH(), address(wstEth), "WSTETH");

        // It should set the slippage tolerance.
        assertEq(adapter.slippageTolerance(), SLIPPAGE_TOLERANCE, "slippageTolerance");

        // It should set the fee on yield.
        assertEq(adapter.feeOnYield(), YIELD_FEE, "feeOnYield");

        // It should be able to receive ETH.
        payable(address(adapter)).transfer(1 ether);

        // It should approve wstETH contract to spend stETH.
        assertEq(steth.allowance(address(adapter), address(wstEth)), MAX_UINT128, "wstETH allowance");

        // It should approve Curve pool to spend stETH.
        assertEq(steth.allowance(address(adapter), address(curvePool)), MAX_UINT128, "curve pool allowance");
    }
}
