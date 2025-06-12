// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IAdminable } from "src/interfaces/IAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract TransferAdmin_Adminable_Concrete_Test is Base_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        setMsgSender(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.eve));
        adminable.transferAdmin(users.eve);
    }

    function test_WhenNewAdminSameAsCurrentAdmin() external whenCallerAdmin {
        // Transfer the admin to the same admin.
        _testTransferAdmin({ newAdmin: admin });
    }

    function test_WhenNewAdminZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // Transfer the admin to zero address.
        _testTransferAdmin({ newAdmin: address(0) });
    }

    function test_WhenNewAdminNotZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // Transfer the admin to Alice.
        _testTransferAdmin({ newAdmin: users.alice });
    }

    /// @dev Private function to test transfer admin.
    function _testTransferAdmin(address newAdmin) private {
        // It should emit {TransferAdmin} event.
        vm.expectEmit({ emitter: address(adminable) });
        emit IAdminable.TransferAdmin(admin, newAdmin);

        // Transfer the admin.
        adminable.transferAdmin(newAdmin);

        // It should set the new admin.
        address actualAdmin = adminable.admin();
        assertEq(actualAdmin, newAdmin, "admin");
    }
}
