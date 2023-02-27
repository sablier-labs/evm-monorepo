// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Events } from "src/libraries/Events.sol";

import { Comptroller_Fuzz_Test } from "../Comptroller.t.sol";

contract SetProtocolFee_Fuzz_Test is Comptroller_Fuzz_Test {
    /// @dev it should set the new protocol fee and emit a {SetProtocolFee} event.
    function testFuzz_SetProtocolFee(UD60x18 newProtocolFee) external {
        newProtocolFee = bound(newProtocolFee, 1, DEFAULT_MAX_FEE);

        // Expect a {SetProtocolFee} event to be emitted.
        expectEmit();
        emit Events.SetProtocolFee({
            admin: users.admin,
            asset: DEFAULT_ASSET,
            oldProtocolFee: ZERO,
            newProtocolFee: newProtocolFee
        });

        // Set the new protocol fee.
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: newProtocolFee });

        // Assert that the protocol fee has been updated.
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(DEFAULT_ASSET);
        UD60x18 expectedProtocolFee = newProtocolFee;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }
}
