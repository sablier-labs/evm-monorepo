// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetSlippageTolerance_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_RevertWhen_SlippageToleranceExceedsMax(uint256 newToleranceRaw) external whenCallerComptroller {
        newToleranceRaw = bound(newToleranceRaw, MAX_SLIPPAGE_TOLERANCE.unwrap() + 1, type(uint256).max);
        UD60x18 newTolerance = ud(newToleranceRaw);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_SlippageToleranceTooHigh.selector, newTolerance, MAX_SLIPPAGE_TOLERANCE
            )
        );
        adapter.setSlippageTolerance(newTolerance);
    }

    function testFuzz_SetSlippageTolerance(uint256 newToleranceRaw) external whenCallerComptroller {
        newToleranceRaw = bound(newToleranceRaw, 0, MAX_SLIPPAGE_TOLERANCE.unwrap());
        UD60x18 newTolerance = ud(newToleranceRaw);

        // It should emit a {SetSlippageTolerance} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.SetSlippageTolerance({
            previousTolerance: adapter.slippageTolerance(),
            newTolerance: newTolerance
        });

        adapter.setSlippageTolerance(newTolerance);

        // It should update the slippage tolerance.
        assertEq(adapter.slippageTolerance(), newTolerance, "slippageTolerance");
    }
}
