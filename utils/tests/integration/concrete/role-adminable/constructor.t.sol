// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Base_Test } from "../../../Base.t.sol";

contract RoleAdminable_Constructor_Concrete_Test is Base_Test {
    function test_Constructor() public view {
        // Assert the state variables.
        assertEq(roleAdminable.admin(), admin, "admin");
        assertEq(roleAdminable.FEE_COLLECTOR_ROLE(), FEE_COLLECTOR_ROLE, "fee collector role");
        assertEq(roleAdminable.FEE_MANAGEMENT_ROLE(), FEE_MANAGEMENT_ROLE, "fee management role");

        // Assert that the accountant has the role.
        assertTrue(
            roleAdminable.hasRoleOrIsAdmin(roleAdminable.FEE_COLLECTOR_ROLE(), users.accountant), "accountant role"
        );
    }
}
