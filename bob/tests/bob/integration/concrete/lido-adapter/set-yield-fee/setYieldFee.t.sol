// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetYieldFee_Integration_Concrete_Test is Integration_Test {
    UD60x18 internal newYieldFee = ud(0.15e18);

    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.depositor
            )
        );
        adapter.setYieldFee(newYieldFee);
    }

    function test_RevertWhen_YieldFeeExceedsMax() external whenCallerComptroller {
        newYieldFee = MAX_YIELD_FEE.add(UNIT);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_YieldFeeTooHigh.selector, newYieldFee, MAX_YIELD_FEE)
        );
        adapter.setYieldFee(newYieldFee);
    }

    function test_WhenYieldFeeNotExceedMax() external whenCallerComptroller {
        // It should emit a {SetYieldFee} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.SetYieldFee({ oldFee: YIELD_FEE, newFee: newYieldFee });

        adapter.setYieldFee(newYieldFee);

        // It should set the new yield fee.
        assertEq(adapter.feeOnYield(), newYieldFee, "yieldFee");
    }
}
