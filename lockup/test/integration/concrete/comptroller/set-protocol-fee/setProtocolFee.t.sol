// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetProtocolFee_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: MAX_FEE });
    }

    /// @dev The Admin is the default caller in the comptroller tests.
    modifier whenCallerAdmin() {
        _;
    }

    function test_SetProtocolFee_SameFee() external whenCallerAdmin {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(comptroller) });
        emit SetProtocolFee({ admin: users.admin, asset: dai, oldProtocolFee: ZERO, newProtocolFee: ZERO });

        // Set the same protocol fee.
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: ZERO });

        // Assert that the protocol fee has not changed.
        UD60x18 actualProtocolFee = comptroller.protocolFees(dai);
        UD60x18 expectedProtocolFee = ZERO;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }

    modifier whenNewFee() {
        _;
    }

    function test_SetProtocolFee() external whenCallerAdmin whenNewFee {
        UD60x18 newProtocolFee = defaults.FLASH_FEE();

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
