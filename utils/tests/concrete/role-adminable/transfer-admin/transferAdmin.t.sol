// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IRoleAdminable } from "src/interfaces/IRoleAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { RoleAdminable_Unit_Concrete_Test } from "../RoleAdminable.t.sol";

contract TransferAdmin_RoleAdminable_Unit_Concrete_Test is RoleAdminable_Unit_Concrete_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        setMsgSender(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, eve));
        roleAdminableMock.transferAdmin(eve);
    }

    modifier whenCallerAdmin() {
        _;
    }

    function test_WhenNewAdminSameAsCurrentAdmin() external whenCallerAdmin {
        // Transfer the admin role to the same admin.
        _testTransferAdmin(admin, admin);
    }

    modifier whenNewAdminNotSameAsCurrentAdmin() {
        _;
    }

    function test_WhenNewAdminZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // Transfer the admin role to the zero address.
        _testTransferAdmin(admin, address(0));

        // It should revoke the admin role.
        bool hasOldAdminRole = roleAdminableMock.hasRole(DEFAULT_ADMIN_ROLE, admin);
        assertFalse(hasOldAdminRole, "hasRole");
    }

    function test_WhenNewAdminNotZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // Transfer the admin role to Alice.
        _testTransferAdmin(admin, alice);

        // It should revoke the admin role from the old admin.
        bool hasOldAdminRole = roleAdminableMock.hasRole(DEFAULT_ADMIN_ROLE, admin);
        assertFalse(hasOldAdminRole, "hasRole");
    }

    /// @dev Private function to test transfer admin.
    function _testTransferAdmin(address oldAdmin, address newAdmin) private {
        // It should emit {RoleRevoked}, {RoleGranted} and {TransferAdmin} events.
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IAccessControl.RoleRevoked({ role: DEFAULT_ADMIN_ROLE, account: oldAdmin, sender: oldAdmin });
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IAccessControl.RoleGranted({ role: DEFAULT_ADMIN_ROLE, account: newAdmin, sender: oldAdmin });
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IRoleAdminable.TransferAdmin(oldAdmin, newAdmin);

        // Transfer the admin.
        roleAdminableMock.transferAdmin(newAdmin);

        // It should set the new admin.
        address actualAdmin = roleAdminableMock.admin();
        assertEq(actualAdmin, newAdmin, "admin");

        // It should grant the admin role to new admin.
        bool hasNewAdminRole = roleAdminableMock.hasRole(DEFAULT_ADMIN_ROLE, newAdmin);
        assertTrue(hasNewAdminRole, "hasRole");
    }
}
