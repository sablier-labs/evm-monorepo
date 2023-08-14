// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Comptroller_Unit_Concrete_Test } from "../Comptroller.t.sol";

contract SetFlashFee_Unit_Concrete_Test is Comptroller_Unit_Concrete_Test {
    function setUp() public virtual override {
        Comptroller_Unit_Concrete_Test.setUp();
        // Make the Admin the default caller in this test suite.
        vm.startPrank({ msgSender: users.admin });
    }

    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        comptroller.setFlashFee({ newFlashFee: MAX_FEE });
    }

    /// @dev The admin is the default caller in the comptroller tests.
    modifier whenCallerAdmin() {
        _;
    }

    function test_SetFlashFee_SameFee() external whenCallerAdmin {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(comptroller) });
        emit SetFlashFee({ admin: users.admin, oldFlashFee: ZERO, newFlashFee: ZERO });
        comptroller.setFlashFee({ newFlashFee: ZERO });

        // She the same flash fee.
        comptroller.setFlashFee({ newFlashFee: ZERO });

        // Assert that the flash fee has not changed.
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = ZERO;
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }

    modifier whenNewFee() {
        _;
    }

    function test_SetFlashFee() external whenCallerAdmin whenNewFee {
        UD60x18 newFlashFee = defaults.FLASH_FEE();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(comptroller) });
        emit SetFlashFee({ admin: users.admin, oldFlashFee: ZERO, newFlashFee: newFlashFee });

        // She the new flash fee.
        comptroller.setFlashFee(newFlashFee);

        // Assert that the flash fee has been updated.
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = newFlashFee;
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }
}
