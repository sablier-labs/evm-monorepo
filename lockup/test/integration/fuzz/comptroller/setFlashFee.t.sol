// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetFlashFee_Integration_Fuzz_Test is Integration_Test {
    modifier whenCallerAdmin() {
        _;
    }

    function testFuzz_SetFlashFee(UD60x18 newFlashFee) external whenCallerAdmin {
        newFlashFee = _bound(newFlashFee, 0, MAX_FEE);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(comptroller) });
        emit SetFlashFee({ admin: users.admin, oldFlashFee: ZERO, newFlashFee: newFlashFee });

        // Set the new flash fee.
        comptroller.setFlashFee(newFlashFee);

        // Assert that the flash fee has been updated.
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = newFlashFee;
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }
}
