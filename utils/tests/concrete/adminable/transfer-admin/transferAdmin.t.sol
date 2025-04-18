// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IAdminable } from "src/interfaces/IAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Adminable_Unit_Concrete_Test } from "../Adminable.t.sol";

contract TransferAdmin_Adminable_Unit_Concrete_Test is Adminable_Unit_Concrete_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        setMsgSender(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, eve));
        adminableMock.transferAdmin(eve);
    }

    function test_WhenNewAdminSameAsCurrentAdmin() external whenCallerAdmin {
        // Transfer the admin to the same admin.
        _testTransferAdmin(admin, admin);
    }

    function test_WhenNewAdminZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // Transfer the admin to zero address.
        _testTransferAdmin(admin, address(0));
    }

    function test_WhenNewAdminNotZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // Transfer the admin to Alice.
        _testTransferAdmin(admin, alice);
    }

    /// @dev Private function to test transfer admin.
    function _testTransferAdmin(address oldAdmin, address newAdmin) private {
        // It should emit {TransferAdmin} event.
        vm.expectEmit({ emitter: address(adminableMock) });
        emit IAdminable.TransferAdmin(oldAdmin, newAdmin);

        // Transfer the admin.
        adminableMock.transferAdmin(newAdmin);

        // It should set the new admin.
        address actualAdmin = adminableMock.admin();
        assertEq(actualAdmin, newAdmin, "admin");
    }
}
