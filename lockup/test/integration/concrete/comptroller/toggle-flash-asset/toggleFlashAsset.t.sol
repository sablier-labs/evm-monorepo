// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract ToggleFlashAsset_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        comptroller.toggleFlashAsset(dai);
    }

    /// @dev The admin is the default caller in the comptroller tests.
    modifier whenCallerAdmin() {
        _;
    }

    function test_ToggleFlashAsset_FlagNotEnabled() external whenCallerAdmin {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ToggleFlashAsset({ admin: users.admin, asset: dai, newFlag: true });

        // Toggle the flash asset.
        comptroller.toggleFlashAsset(dai);

        // Assert that the flash asset has been toggled.
        bool isFlashAsset = comptroller.isFlashAsset(dai);
        assertTrue(isFlashAsset, "isFlashAsset");
    }

    modifier whenFlagEnabled() {
        comptroller.toggleFlashAsset(dai);
        _;
    }

    function test_ToggleFlashAsset() external whenCallerAdmin whenFlagEnabled {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ToggleFlashAsset({ admin: users.admin, asset: dai, newFlag: false });

        // Toggle the flash asset.
        comptroller.toggleFlashAsset(dai);

        // Assert that the flash asset has been toggled.
        bool isFlashAsset = comptroller.isFlashAsset(dai);
        assertFalse(isFlashAsset, "isFlashAsset");
    }
}
