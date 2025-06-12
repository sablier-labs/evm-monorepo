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

        // Assert that it returns true with existing admin.
        bool actualHasRole = roleAdminable.hasRoleOrIsAdmin({ role: role, account: admin });
        assertTrue(actualHasRole, "hasRoleOrIsAdmin admin");

        // Transfer the ownership to the `newAdmin`.
        roleAdminable.transferAdmin(newAdmin);

        // Change caller to `newAdmin`.
        setMsgSender(newAdmin);

        // Assert that it returns false with old admin.
        actualHasRole = roleAdminable.hasRoleOrIsAdmin({ role: role, account: admin });
        assertFalse(actualHasRole, "hasRoleOrIsAdmin oldAdmin");

        // Assert that it returns true with new admin.
        actualHasRole = roleAdminable.hasRoleOrIsAdmin({ role: role, account: newAdmin });
        assertTrue(actualHasRole, "hasRoleOrIsAdmin newAdmin");

        // Assert that `newAccountant` has no role.
        actualHasRole = roleAdminable.hasRoleOrIsAdmin({ role: role, account: newAccountant });
        assertFalse(actualHasRole, "hasRoleOrIsAdmin newAccountant");

        // Grant role to the `newAccountant`.
        roleAdminable.grantRole({ role: role, account: newAccountant });

        // Assert that `newAccountant` has the role.
        actualHasRole = roleAdminable.hasRoleOrIsAdmin({ role: role, account: newAccountant });
        assertTrue(actualHasRole, "hasRoleOrIsAdmin newAccountant");

        // Revoke role from the `newAccountant`.
        roleAdminable.revokeRole({ role: role, account: newAccountant });

        // Assert that `newAccountant` has no role.
        actualHasRole = roleAdminable.hasRoleOrIsAdmin({ role: role, account: newAccountant });
        assertFalse(actualHasRole, "hasRoleOrIsAdmin newAccountant");
    }
}
