// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Base_Test } from "../../../Base.t.sol";

contract HasRoleOrIsAdmin_RoleAdminable_Fuzz_Test is Base_Test {
    /// @dev It would test the following scenarios:
    /// - `admin` bypasses any arbitrary role check.
    /// - When ownership is transferred, the `newAdmin` bypasses any arbitrary role check.
    /// - When ownership is transferred, the role check returns `false` for the old admin.
    /// - When role is granted to an account, the role check returns `true` for that account.
    /// - When role is revoked from an account, the role check returns `false` for that account.
    function testFuzz_HasRoleOrIsAdmin(address newAdmin, address newAccountant, bytes32 role) external {
        vm.assume(newAdmin != admin && newAdmin != users.accountant);
        vm.assume(newAccountant != admin && newAccountant != users.accountant);
        vm.assume(newAdmin != newAccountant);

        // It should return true with the existing admin.
        bool actualHasRole = roleAdminableMock.hasRoleOrIsAdmin({ role: role, account: admin });
        assertTrue(actualHasRole, "hasRoleOrIsAdmin admin");

        // Transfer the ownership to the `newAdmin`.
        roleAdminableMock.transferAdmin(newAdmin);

        // Change caller to `newAdmin`.
        setMsgSender(newAdmin);

        // It should return false with the old admin.
        actualHasRole = roleAdminableMock.hasRoleOrIsAdmin({ role: role, account: admin });
        assertFalse(actualHasRole, "hasRoleOrIsAdmin oldAdmin");

        // It should return true with the new admin.
        actualHasRole = roleAdminableMock.hasRoleOrIsAdmin({ role: role, account: newAdmin });
        assertTrue(actualHasRole, "hasRoleOrIsAdmin newAdmin");

        // It should show `newAccountant` has no role.
        actualHasRole = roleAdminableMock.hasRoleOrIsAdmin({ role: role, account: newAccountant });
        assertFalse(actualHasRole, "hasRoleOrIsAdmin newAccountant");

        // Grant role to the `newAccountant`.
        roleAdminableMock.grantRole({ role: role, account: newAccountant });

        // It should show `newAccountant` has the role.
        actualHasRole = roleAdminableMock.hasRoleOrIsAdmin({ role: role, account: newAccountant });
        assertTrue(actualHasRole, "hasRoleOrIsAdmin newAccountant");

        // Revoke role from the `newAccountant`.
        roleAdminableMock.revokeRole({ role: role, account: newAccountant });

        // It should show `newAccountant` has no role.
        actualHasRole = roleAdminableMock.hasRoleOrIsAdmin({ role: role, account: newAccountant });
        assertFalse(actualHasRole, "hasRoleOrIsAdmin newAccountant");
    }
}
