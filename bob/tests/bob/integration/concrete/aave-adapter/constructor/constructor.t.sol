// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { SablierAaveAdapter } from "src/SablierAaveAdapter.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Constructor_AaveAdapter_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_YieldFeeExceedsMax() external {
        UD60x18 yieldFee = MAX_YIELD_FEE.add(UNIT);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierAaveAdapter_YieldFeeTooHigh.selector, yieldFee, MAX_YIELD_FEE)
        );

        new SablierAaveAdapter({
            aavePoolAddressesProvider: address(aavePoolAddressesProvider),
            initialComptroller: address(comptroller),
            initialYieldFee: yieldFee,
            sablierBob: address(bob)
        });
    }

    function test_WhenYieldFeeNotExceedMax() external {
        // Deploy a new adapter.
        SablierAaveAdapter newAdapter = new SablierAaveAdapter({
            aavePoolAddressesProvider: address(aavePoolAddressesProvider),
            initialComptroller: address(comptroller),
            initialYieldFee: YIELD_FEE,
            sablierBob: address(bob)
        });

        // It should set the comptroller.
        assertEq(address(newAdapter.comptroller()), address(comptroller), "comptroller");

        // It should set the AAVE_POOL via addresses provider.
        assertEq(address(newAdapter.AAVE_POOL()), address(aavePool), "AAVE_POOL");

        // It should set the AAVE_POOL_DATA_PROVIDER via addresses provider.
        assertEq(newAdapter.AAVE_POOL_DATA_PROVIDER(), address(aavePoolDataProvider), "AAVE_POOL_DATA_PROVIDER");

        // It should set SABLIER_BOB.
        assertEq(newAdapter.SABLIER_BOB(), address(bob), "SABLIER_BOB");

        // It should set the fee on yield.
        assertEq(newAdapter.feeOnYield(), YIELD_FEE, "feeOnYield");
    }
}
