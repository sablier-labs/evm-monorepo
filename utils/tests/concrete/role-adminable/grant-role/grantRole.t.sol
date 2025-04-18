// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IRoleAdminable } from "src/interfaces/IRoleAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";
import { RoleAdminable_Unit_Concrete_Test } from "../RoleAdminable.t.sol";

contract GrantRole_RoleAdminable_Unit_Concrete_Test is RoleAdminable_Unit_Concrete_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Accountant the caller in this test.
        setMsgSender(accountant);

        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, accountant));
        roleAdminableMock.grantRole(FEE_COLLECTOR_ROLE, accountant);
    }

    function test_RevertGiven_AccountHasRole() external whenCallerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.AccountAlreadyHasRole.selector, FEE_COLLECTOR_ROLE, accountant));
        roleAdminableMock.grantRole(FEE_COLLECTOR_ROLE, accountant);
    }

    function test_GivenAccountNotHaveRole() external whenCallerAdmin {
        // It should emit {RoleGranted} event.
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IRoleAdminable.RoleGranted({ admin: admin, account: eve, role: FEE_COLLECTOR_ROLE });

        // Grant the role to Eve.
        roleAdminableMock.grantRole(FEE_COLLECTOR_ROLE, eve);

        // It should grant role to the account.
        assertTrue(roleAdminableMock.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, eve), "hasRole");
    }
}
