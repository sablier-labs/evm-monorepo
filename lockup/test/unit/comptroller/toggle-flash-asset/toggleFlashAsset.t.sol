// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract ToggleFlashAsset_Unit_Test is Comptroller_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Adminable_CallerNotAdmin.selector, users.admin, users.eve)
        );
        comptroller.toggleFlashAsset(DEFAULT_ASSET);
    }

    /// @dev The admin is the default caller in the comptroller tests.
    modifier callerAdmin() {
        _;
    }

    /// @dev it should toggle the flash asset.
    function test_ToggleFlashAsset_FlagNotEnabled() external callerAdmin {
        // Expect a {ToggleFlashAsset} event to be emitted.
        expectEmit();
        emit ToggleFlashAsset({ admin: users.admin, asset: DEFAULT_ASSET, newFlag: true });

        // Toggle the flash asset.
        comptroller.toggleFlashAsset(DEFAULT_ASSET);

        // Assert that the flash asset has been toggled.
        bool isFlashLoanable = comptroller.isFlashLoanable(DEFAULT_ASSET);
        assertTrue(isFlashLoanable, "isFlashLoanable");
    }

    modifier flagEnabled() {
        comptroller.toggleFlashAsset(DEFAULT_ASSET);
        _;
    }

    /// @dev it should toggle the flash asset and emit a {ToggleFlashAsset} event.
    function test_ToggleFlashAsset() external callerAdmin flagEnabled {
        // Expect a {ToggleFlashAsset} event to be emitted.
        expectEmit();
        emit ToggleFlashAsset({ admin: users.admin, asset: DEFAULT_ASSET, newFlag: false });

        // Toggle the flash asset.
        comptroller.toggleFlashAsset(DEFAULT_ASSET);

        // Assert that the flash asset has been toggled.

        bool isFlashLoanable = comptroller.isFlashLoanable(DEFAULT_ASSET);
        assertFalse(isFlashLoanable, "isFlashLoanable");
    }
}
