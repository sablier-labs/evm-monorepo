// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IRoleAdminable } from "src/interfaces/IRoleAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Base_Test } from "../../../../Base.t.sol";

contract GrantRole_RoleAdminable_Concrete_Test is Base_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Accountant the caller in this test.
        setMsgSender(users.accountant);

        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.accountant));
        roleAdminable.grantRole(FEE_COLLECTOR_ROLE, users.accountant);
    }

    function test_RevertGiven_AccountHasRole() external whenCallerAdmin {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccountAlreadyHasRole.selector, FEE_COLLECTOR_ROLE, users.accountant)
        );
        roleAdminable.grantRole(FEE_COLLECTOR_ROLE, users.accountant);
    }

    function test_GivenAccountNotHaveRole() external whenCallerAdmin {
        // It should emit {RoleGranted} event.
        vm.expectEmit({ emitter: address(roleAdminable) });
        emit IRoleAdminable.RoleGranted({ admin: admin, account: users.eve, role: FEE_COLLECTOR_ROLE });

        // Grant the role to Eve.
        roleAdminable.grantRole(FEE_COLLECTOR_ROLE, users.eve);

        // It should grant role to the account.
        assertTrue(roleAdminable.hasRoleOrIsAdmin(FEE_COLLECTOR_ROLE, users.eve), "hasRole");
    }
}
