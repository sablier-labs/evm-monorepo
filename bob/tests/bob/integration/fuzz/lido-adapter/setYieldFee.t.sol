// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetYieldFee_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_RevertWhen_YieldFeeExceedsMax(uint256 newFeeRaw) external whenCallerComptroller {
        newFeeRaw = bound(newFeeRaw, MAX_YIELD_FEE.unwrap() + 1, type(uint256).max);
        UD60x18 newFee = ud(newFeeRaw);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_YieldFeeTooHigh.selector, newFee, MAX_YIELD_FEE)
        );
        adapter.setYieldFee(newFee);
    }

    function testFuzz_SetYieldFee(uint256 newFeeRaw) external whenCallerComptroller {
        newFeeRaw = bound(newFeeRaw, 0, MAX_YIELD_FEE.unwrap());
        UD60x18 newFee = ud(newFeeRaw);

        // It should emit a {SetYieldFee} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.SetYieldFee({ previousFee: adapter.feeOnYield(), newFee: newFee });

        adapter.setYieldFee(newFee);

        // It should update the yield fee.
        assertEq(adapter.feeOnYield(), newFee, "feeOnYield");
    }
}
