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
        comptroller.toggleFlashAsset(dai);
    }

    modifier callerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank(users.admin);
        _;
    }

    /// @dev it should toggle the flash asset.
    function test_ToggleFlashAsset_FlagNotEnabled() external callerAdmin {
        comptroller.toggleFlashAsset(dai);
        bool isFlashLoanable = comptroller.isFlashLoanable(dai);
        assertTrue(isFlashLoanable);
    }

    /// @dev it should emit a ToggleFlashAsset event.
    function test_ToggleFlashAsset_FlagNotEnabled_Event() external callerAdmin {
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.ToggleFlashAsset({ admin: users.admin, asset: dai, newFlag: true });
        comptroller.toggleFlashAsset(dai);
    }

    modifier flagEnabled() {
        comptroller.toggleFlashAsset(dai);
        _;
    }

    /// @dev it should toggle the flash asset.
    function test_ToggleFlashAsset_FlagEnabled() external callerAdmin flagEnabled {
        comptroller.toggleFlashAsset(dai);
        bool isFlashLoanable = comptroller.isFlashLoanable(dai);
        assertFalse(isFlashLoanable);
    }

    /// @dev it should emit a ToggleFlashAsset event.
    function test_ToggleFlashAsset_FlagEnabled_Event() external callerAdmin flagEnabled {
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.ToggleFlashAsset({ admin: users.admin, asset: dai, newFlag: false });
        comptroller.toggleFlashAsset(dai);
    }
}
