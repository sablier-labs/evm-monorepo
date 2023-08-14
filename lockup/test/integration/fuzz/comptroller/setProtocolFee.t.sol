// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetProtocolFee_Integration_Fuzz_Test is Integration_Test {
    modifier whenCallerAdmin() {
        _;
    }

    function testFuzz_SetProtocolFee(UD60x18 newProtocolFee) external whenCallerAdmin {
        newProtocolFee = _bound(newProtocolFee, 1, MAX_FEE);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(comptroller) });
        emit SetProtocolFee({ admin: users.admin, asset: dai, oldProtocolFee: ZERO, newProtocolFee: newProtocolFee });

        // Set the new protocol fee.
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: newProtocolFee });

        // Assert that the protocol fee has been updated.
        UD60x18 actualProtocolFee = comptroller.protocolFees(dai);
        UD60x18 expectedProtocolFee = newProtocolFee;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }
}
