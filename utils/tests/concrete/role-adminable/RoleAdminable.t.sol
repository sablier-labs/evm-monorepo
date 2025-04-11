// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { RoleAdminableMock } from "src/mocks/RoleAdminableMock.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract RoleAdminable_Unit_Concrete_Test is Unit_Test {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");

    RoleAdminableMock internal roleAdminableMock;

    function setUp() public override {
        Unit_Test.setUp();

        roleAdminableMock = new RoleAdminableMock(admin);
        setMsgSender(admin);

        // It should grant the default role to the admin.
        bool actualHasRole = roleAdminableMock.hasRole(DEFAULT_ADMIN_ROLE, admin);
        assertTrue(actualHasRole, "hasRole");
    }
}
