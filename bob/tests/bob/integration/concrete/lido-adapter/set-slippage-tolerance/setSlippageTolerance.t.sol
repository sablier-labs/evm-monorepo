// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetSlippageTolerance_Integration_Concrete_Test is Integration_Test {
    UD60x18 internal newSlippageTolerance = ud(0.01e18);

    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.depositor
            )
        );
        adapter.setSlippageTolerance(newSlippageTolerance);
    }

    function test_RevertWhen_SlippageToleranceExceedsMax() external whenCallerComptroller {
        newSlippageTolerance = MAX_SLIPPAGE_TOLERANCE.add(UNIT);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_SlippageToleranceTooHigh.selector,
                newSlippageTolerance,
                MAX_SLIPPAGE_TOLERANCE
            )
        );
        adapter.setSlippageTolerance(newSlippageTolerance);
    }

    function test_WhenSlippageToleranceNotExceedMax() external whenCallerComptroller {
        // It should emit a {SetSlippageTolerance} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.SetSlippageTolerance({
            previousTolerance: SLIPPAGE_TOLERANCE,
            newTolerance: newSlippageTolerance
        });

        adapter.setSlippageTolerance(newSlippageTolerance);

        // It should update the slippage tolerance.
        assertEq(adapter.slippageTolerance(), newSlippageTolerance, "slippageTolerance");
    }
}
