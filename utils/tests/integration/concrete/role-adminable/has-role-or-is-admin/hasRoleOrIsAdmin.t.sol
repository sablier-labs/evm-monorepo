// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Base_Test } from "../../../../Base.t.sol";

contract HasRoleOrIsAdmin_RoleAdminable_Concrete_Test is Base_Test {
    function test_WhenAccountAdmin() external view {
        // It should return true.
        bool actualHasRole = roleAdminable.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, admin);
        assertTrue(actualHasRole, "hasRoleOrIsAdmin");
    }

    function test_WhenAccountHasRole() external view whenAccountNotAdmin {
        // It should return true.
        bool actualHasRole = roleAdminable.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, users.accountant);
        assertTrue(actualHasRole, "hasRoleOrIsAdmin");
    }

    function test_WhenAccountNotHaveRole() external view whenAccountNotAdmin {
        // It should return false.
        bool actualHasRole = roleAdminable.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, users.eve);
        assertFalse(actualHasRole, "hasRoleOrIsAdmin");
    }
}
