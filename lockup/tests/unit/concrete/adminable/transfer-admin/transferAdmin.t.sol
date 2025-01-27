// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IAdminable } from "src/interfaces/IAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Adminable_Unit_Shared_Test } from "../../../shared/Adminable.t.sol";

contract TransferAdmin_Unit_Concrete_Test is Adminable_Unit_Shared_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        resetPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        adminableMock.transferAdmin(users.eve);
    }

    function test_WhenNewAdminSameAsCurrentAdmin() external whenCallerAdmin {
        // It should emit a {TransferAdmin} event.
        vm.expectEmit({ emitter: address(adminableMock) });
        emit IAdminable.TransferAdmin({ oldAdmin: users.admin, newAdmin: users.admin });

        // Transfer the admin.
        adminableMock.transferAdmin(users.admin);

        // It should keep the same admin.
        address actualAdmin = adminableMock.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }

    function test_WhenNewAdminZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // It should emit a {TransferAdmin}.
        vm.expectEmit({ emitter: address(adminableMock) });
        emit IAdminable.TransferAdmin({ oldAdmin: users.admin, newAdmin: address(0) });

        // Transfer the admin.
        adminableMock.transferAdmin(address(0));

        // It should set the admin to the zero address.
        address actualAdmin = adminableMock.admin();
        address expectedAdmin = address(0);
        assertEq(actualAdmin, expectedAdmin, "admin");
    }

    function test_WhenNewAdminNotZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // It should emit a {TransferAdmin} event.
        vm.expectEmit({ emitter: address(adminableMock) });
        emit IAdminable.TransferAdmin({ oldAdmin: users.admin, newAdmin: users.alice });

        // Transfer the admin.
        adminableMock.transferAdmin(users.alice);

        // It should set the new admin.
        address actualAdmin = adminableMock.admin();
        address expectedAdmin = users.alice;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }
}
