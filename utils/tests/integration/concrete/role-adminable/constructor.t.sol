// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Base_Test } from "../../../Base.t.sol";

contract Constructor_RoleAdminable_Concrete_Test is Base_Test {
    function test_Constructor() public view {
        // Assert the state variables.
        assertEq(roleAdminableMock.admin(), admin, "admin");
        assertEq(roleAdminableMock.FEE_COLLECTOR_ROLE(), FEE_COLLECTOR_ROLE, "fee collector role");
        assertEq(roleAdminableMock.FEE_MANAGEMENT_ROLE(), FEE_MANAGEMENT_ROLE, "fee management role");

        // Assert that the accountant has the role.
        assertTrue(
            roleAdminableMock.hasRoleOrIsAdmin(roleAdminableMock.FEE_COLLECTOR_ROLE(), users.accountant),
            "accountant role"
        );
    }
}
