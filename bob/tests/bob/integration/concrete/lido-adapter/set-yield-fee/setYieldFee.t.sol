// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetYieldFee_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        setMsgSender(users.newDepositor);
    }

    function test_RevertWhen_CallerNotComptroller() external {
        // Cache the yield fee before expectRevert, since YIELD_FEE is a view call
        // that would be interpreted as the "next call" by expectRevert.
        UD60x18 newFee = YIELD_FEE;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.newDepositor
            )
        );
        adapter.setYieldFee(newFee);
    }

    function test_RevertWhen_FeeExceedsMax() external whenCallerComptroller {
        UD60x18 maxFee = adapter.MAX_FEE();
        UD60x18 excessiveFee = maxFee.add(ud(1));

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_YieldFeeTooHigh.selector, excessiveFee.unwrap(), maxFee.unwrap()
            )
        );
        adapter.setYieldFee(excessiveFee);
    }

    function test_WhenFeeWithinLimit() external whenCallerComptroller {
        UD60x18 oldFee = adapter.feeOnYield();

        // It should emit a {SetYieldFee} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.SetYieldFee({ oldFee: oldFee, newFee: YIELD_FEE });

        adapter.setYieldFee(YIELD_FEE);

        // It should update the yield fee.
        assertEq(adapter.feeOnYield().unwrap(), YIELD_FEE.unwrap(), "yieldFee");
    }
}
