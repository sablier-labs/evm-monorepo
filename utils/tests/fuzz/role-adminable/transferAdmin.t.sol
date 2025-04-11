// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IRoleAdminable } from "src/interfaces/IRoleAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { RoleAdminableMock } from "src/mocks/RoleAdminableMock.sol";
import { Unit_Test } from "../../Unit.t.sol";

contract TransferAdmin_RoleAdminable_Unit_Fuzz_Test is Unit_Test {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    RoleAdminableMock internal roleAdminableMock;

    function setUp() public override {
        Unit_Test.setUp();

        roleAdminableMock = new RoleAdminableMock(admin);
        setMsgSender(admin);
    }

    function testFuzz_RevertWhen_CallerNotAdmin(address eve) external {
        vm.assume(eve != address(0) && eve != admin);
        assumeNotPrecompile(eve);

        // Make Eve the caller in this test.
        setMsgSender(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, eve));
        roleAdminableMock.transferAdmin(eve);
    }

    modifier whenCallerAdmin() {
        _;
    }

    function testFuzz_TransferAdmin(address newAdmin) external whenCallerAdmin {
        vm.assume(newAdmin != address(0));

        // It should emit {RoleRevoked}, {RoleGranted} and {TransferAdmin} events.
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IAccessControl.RoleRevoked({ role: DEFAULT_ADMIN_ROLE, account: admin, sender: admin });
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IAccessControl.RoleGranted({ role: DEFAULT_ADMIN_ROLE, account: newAdmin, sender: admin });
        vm.expectEmit({ emitter: address(roleAdminableMock) });
        emit IRoleAdminable.TransferAdmin(admin, newAdmin);

        // Transfer the admin.
        roleAdminableMock.transferAdmin(newAdmin);

        // Assert that the admin has been transferred.
        address actualAdmin = roleAdminableMock.admin();
        assertEq(actualAdmin, newAdmin, "admin");

        // Assert that the old admin has been revoked the admin role if the new admin is different.
        if (newAdmin != admin) {
            bool hasOldAdminRole = roleAdminableMock.hasRole(DEFAULT_ADMIN_ROLE, admin);
            assertFalse(hasOldAdminRole, "hasRole");
        }

        // Assert that the new admin has been granted the admin role.
        bool hasNewAdminRole = roleAdminableMock.hasRole(DEFAULT_ADMIN_ROLE, newAdmin);
        assertTrue(hasNewAdminRole, "hasRole");
    }
}
