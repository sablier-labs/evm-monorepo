// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetSlippageTolerance_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.bob);
    }

    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.bob
            )
        );
        adapter.setSlippageTolerance(ud(0.01e18));
    }

    function test_RevertWhen_ToleranceExceedsMax() external whenCallerComptroller {
        UD60x18 maxTolerance = adapter.MAX_SLIPPAGE_TOLERANCE();
        UD60x18 invalidTolerance = maxTolerance.add(ud(1));

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_SlippageToleranceTooHigh.selector,
                invalidTolerance.unwrap(),
                maxTolerance.unwrap()
            )
        );
        adapter.setSlippageTolerance(invalidTolerance);
    }

    function test_WhenToleranceWithinLimit() external whenCallerComptroller {
        UD60x18 oldTolerance = adapter.slippageTolerance();
        UD60x18 newTolerance = ud(0.01e18);

        // It should emit a {SetSlippageTolerance} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.SetSlippageTolerance({
            oldSlippageTolerance: oldTolerance,
            newSlippageTolerance: newTolerance
        });

        adapter.setSlippageTolerance(newTolerance);

        // It should update the slippage tolerance.
        assertEq(adapter.slippageTolerance().unwrap(), newTolerance.unwrap(), "slippageTolerance");
    }

    function test_WhenToleranceAtMaximum() external whenCallerComptroller {
        UD60x18 oldTolerance = adapter.slippageTolerance();
        UD60x18 maxTolerance = adapter.MAX_SLIPPAGE_TOLERANCE();

        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.SetSlippageTolerance({
            oldSlippageTolerance: oldTolerance,
            newSlippageTolerance: maxTolerance
        });

        adapter.setSlippageTolerance(maxTolerance);
        assertEq(adapter.slippageTolerance().unwrap(), maxTolerance.unwrap(), "slippageTolerance");
    }

    function test_WhenToleranceZero() external whenCallerComptroller {
        UD60x18 oldTolerance = adapter.slippageTolerance();

        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.SetSlippageTolerance({
            oldSlippageTolerance: oldTolerance,
            newSlippageTolerance: ud(0)
        });

        adapter.setSlippageTolerance(ud(0));
        assertEq(adapter.slippageTolerance().unwrap(), 0, "slippageTolerance");
    }
}
