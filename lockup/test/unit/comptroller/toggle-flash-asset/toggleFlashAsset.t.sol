// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IAdminable } from "@prb/contracts/access/IAdminable.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { Comptroller_Test } from "../Comptroller.t.sol";

contract ToggleFlashAsset_Test is Comptroller_Test {
    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin(address eve) external {
        vm.assume(eve != users.admin);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IAdminable.Adminable_CallerNotAdmin.selector, users.admin, eve));
        comptroller.toggleFlashAsset(DEFAULT_ASSET);
    }

    modifier callerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank(users.admin);
        _;
    }

    /// @dev it should toggle the flash asset.
    function test_ToggleFlashAsset_FlagNotEnabled() external callerAdmin {
        // Expect a {ToggleFlashAsset} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.ToggleFlashAsset({ admin: users.admin, asset: DEFAULT_ASSET, newFlag: true });

        // Toggle the flash asset.
        comptroller.toggleFlashAsset(DEFAULT_ASSET);

        // Assert that the flash asset was toggled.
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
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.ToggleFlashAsset({ admin: users.admin, asset: DEFAULT_ASSET, newFlag: false });

        // Toggle the flash asset.
        comptroller.toggleFlashAsset(DEFAULT_ASSET);

        // Assert that the flash asset was toggled.

        bool isFlashLoanable = comptroller.isFlashLoanable(DEFAULT_ASSET);
        assertFalse(isFlashLoanable, "isFlashLoanable");
    }
}
