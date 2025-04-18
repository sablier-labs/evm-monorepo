// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IRoleAdminable } from "src/interfaces/IRoleAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { RoleAdminable_Fuzz_Test } from "./RoleAdminable.t.sol";

contract RevokeRole_RoleAdminable_Fuzz_Test is RoleAdminable_Fuzz_Test {
    function testFuzz_RevertWhen_CallerNotAdmin(address eve) external {
        vm.assume(eve != address(0) && eve != admin);

        // Make Eve the caller in this test.
        setMsgSender(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, eve));
        roleAdminableMock.revokeRole(FEE_COLLECTOR_ROLE, accountant);
    }

    function testFuzz_RevertWhen_AccountNotHaveRole(address account, bytes32 role) external whenCallerAdmin {
        vm.assume(account != address(0) && account != accountant);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.AccountDoesNotHaveRole.selector, role, account));
        roleAdminableMock.revokeRole(role, account);
    }

    function testFuzz_RevokeRole(address account, bytes32 role) external whenCallerAdmin whenAccountHasRole {
        vm.assume(account != address(0) && account != admin);

        // Grant the role to the account as a precondition.
        roleAdminableMock.grantRole(role, account);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IRoleAdminable.RoleRevoked({ admin: admin, account: account, role: role });

        // Revoke the role from account.
        roleAdminableMock.revokeRole(role, account);

        // Assert that the role has been revoked from the account.
        assertFalse(roleAdminableMock.hasRoleOrIsAdmin(role, account), "hasRole");
    }
}
