// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract SetFlashFee_Unit_Test is Comptroller_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Adminable_CallerNotAdmin.selector, users.admin, users.eve)
        );
        comptroller.setFlashFee({ newFlashFee: DEFAULT_MAX_FEE });
    }

    /// @dev The admin is the default caller in the comptroller tests.
    modifier callerAdmin() {
        _;
    }

    /// @dev it should re-set the flash fee.
    function test_SetFlashFee_SameFee() external callerAdmin {
        comptroller.setFlashFee({ newFlashFee: ZERO });

        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = ZERO;
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }

    modifier newFee() {
        _;
    }

    /// @dev it should set the new flash fee and emit a {SetFlashFee} event.
    function test_SetFlashFee() external {
        UD60x18 newFlashFee = DEFAULT_FLASH_FEE;

        // Expect a {SetFlashFee} event to be emitted.
        expectEmit();
        emit Events.SetFlashFee({ admin: users.admin, oldFlashFee: ZERO, newFlashFee: newFlashFee });

        // She the new flash fee.
        comptroller.setFlashFee(newFlashFee);

        // Assert that the flash fee has been updated.
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = newFlashFee;
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }
}
