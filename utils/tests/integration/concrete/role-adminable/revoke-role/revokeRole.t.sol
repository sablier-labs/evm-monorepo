// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IRoleAdminable } from "src/interfaces/IRoleAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Base_Test } from "../../../../Base.t.sol";

contract RevokeRole_RoleAdminable_Concrete_Test is Base_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Accountant the caller in this test.
        setMsgSender(users.accountant);

        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.accountant));
        roleAdminableMock.revokeRole(FEE_COLLECTOR_ROLE, users.accountant);
    }

    function test_RevertGiven_AccountNotHaveRole() external whenCallerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.AccountDoesNotHaveRole.selector, FEE_COLLECTOR_ROLE, users.eve));
        roleAdminableMock.revokeRole(FEE_COLLECTOR_ROLE, users.eve);
    }

    function test_GivenAccountHasRole() external whenCallerAdmin {
        // It should emit {RoleRevoked} event.
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IRoleAdminable.RoleRevoked({ admin: admin, account: users.accountant, role: FEE_COLLECTOR_ROLE });

        // Revoke the role from accountant.
        roleAdminableMock.revokeRole(FEE_COLLECTOR_ROLE, users.accountant);

        // It should revoke role from the account.
        assertFalse(roleAdminableMock.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, users.accountant), "hasRole");
    }
}
