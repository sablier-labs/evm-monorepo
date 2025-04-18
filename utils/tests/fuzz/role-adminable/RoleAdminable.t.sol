// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { RoleAdminableMock } from "src/mocks/RoleAdminableMock.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract RoleAdminable_Fuzz_Test is Unit_Test {
    RoleAdminableMock internal roleAdminableMock;

    function setUp() public override {
        Unit_Test.setUp();

        roleAdminableMock = new RoleAdminableMock(admin);
        setMsgSender(admin);

        // Grant roles to the accountant.
        roleAdminableMock.grantRole(FEE_COLLECTOR_ROLE, accountant);
        roleAdminableMock.grantRole(FEE_MANAGEMENT_ROLE, accountant);
    }
}
