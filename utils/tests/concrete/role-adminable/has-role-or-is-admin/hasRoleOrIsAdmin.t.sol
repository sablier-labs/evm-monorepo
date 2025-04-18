// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { RoleAdminable_Unit_Concrete_Test } from "../RoleAdminable.t.sol";

contract HasRoleOrIsAdmin_RoleAdminable_Unit_Concrete_Test is RoleAdminable_Unit_Concrete_Test {
    function test_WhenAccountAdmin() external view {
        // It should return true.
        bool actualHasRole = roleAdminableMock.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, admin);
        assertTrue(actualHasRole, "hasRoleOrIsAdmin");
    }

    function test_WhenAccountHasRole() external view whenAccountNotAdmin {
        // It should return true.
        bool actualHasRole = roleAdminableMock.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, accountant);
        assertTrue(actualHasRole, "hasRoleOrIsAdmin");
    }

    function test_WhenAccountNotHaveRole() external view whenAccountNotAdmin {
        // It should return false.
        bool actualHasRole = roleAdminableMock.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, eve);
        assertFalse(actualHasRole, "hasRoleOrIsAdmin");
    }
}
