// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { RoleAdminableMock } from "src/mocks/RoleAdminableMock.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract RoleAdminable_Unit_Concrete_Test is Unit_Test {
    RoleAdminableMock internal roleAdminableMock;

    function setUp() public override {
        Unit_Test.setUp();

        roleAdminableMock = new RoleAdminableMock(admin);
        setMsgSender(admin);

        // Grant role to the accountant.
        roleAdminableMock.grantRole(roleAdminableMock.FEE_COLLECTOR_ROLE(), accountant);

        // Assert the state variables.
        assertEq(roleAdminableMock.admin(), admin, "admin");
        assertEq(roleAdminableMock.FEE_COLLECTOR_ROLE(), FEE_COLLECTOR_ROLE, "fee collector role");
        assertEq(roleAdminableMock.FEE_MANAGEMENT_ROLE(), FEE_MANAGEMENT_ROLE, "fee management role");

        // Assert that the accountant has the role.
        assertTrue(
            roleAdminableMock.hasRoleOrIsAdmin(roleAdminableMock.FEE_COLLECTOR_ROLE(), accountant), "accountant role"
        );
    }
}
