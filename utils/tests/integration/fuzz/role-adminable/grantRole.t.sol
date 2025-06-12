// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IRoleAdminable } from "src/interfaces/IRoleAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../../../Base.t.sol";

contract GrantRole_RoleAdminable_Fuzz_Test is Base_Test {
    function testFuzz_RevertWhen_CallerNotAdmin(address eve) external {
        vm.assume(eve != address(0) && eve != admin);

        // Make Eve the caller in this test.
        setMsgSender(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, eve));
        roleAdminableMock.grantRole(FEE_COLLECTOR_ROLE, users.accountant);
    }

    function testFuzz_RevertWhen_AccountHasRole(address account, bytes32 role) external whenCallerAdmin {
        vm.assume(account != address(0));

        // Grant the role to the account as a precondition.
        roleAdminableMock.grantRole(role, account);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccountAlreadyHasRole.selector, role, account));
        roleAdminableMock.grantRole(role, account);
    }

    function testFuzz_GrantRole(address account, bytes32 role) external whenCallerAdmin whenAccountNotHaveRole {
        vm.assume(account != address(0) && account != users.accountant && account != admin);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IRoleAdminable.RoleGranted({ admin: admin, account: account, role: role });

        // Grant the role to account.
        roleAdminableMock.grantRole(role, account);

        // Assert that the role has been granted to the account.
        assertTrue(roleAdminableMock.hasRoleOrIsAdmin(role, account), "hasRole");
    }
}
