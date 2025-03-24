// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IAdminable } from "src/interfaces/IAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { AdminableMock } from "src/mocks/AdminableMock.sol";
import { Unit_Test } from "../../Unit.t.sol";

contract TransferAdmin_Unit_Concrete_Test is Unit_Test {
    AdminableMock internal adminableMock;

    function setUp() public override {
        Unit_Test.setUp();

        adminableMock = new AdminableMock(admin);
        setMsgSender(admin);
    }

    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        setMsgSender(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, eve));
        adminableMock.transferAdmin(eve);
    }

    modifier whenCallerAdmin() {
        _;
    }

    function test_WhenNewAdminSameAsCurrentAdmin() external whenCallerAdmin {
        // It should emit a {TransferAdmin} event.
        vm.expectEmit({ emitter: address(adminableMock) });
        emit IAdminable.TransferAdmin({ oldAdmin: admin, newAdmin: admin });

        // Transfer the admin.
        adminableMock.transferAdmin(admin);

        // It should keep the same admin.
        address actualAdmin = adminableMock.admin();
        address expectedAdmin = admin;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }

    modifier whenNewAdminNotSameAsCurrentAdmin() {
        _;
    }

    function test_WhenNewAdminZeroAddress() external whenCallerAdmin whenNewAdminNotSameAsCurrentAdmin {
        // It should emit a {TransferAdmin}.
        vm.expectEmit({ emitter: address(adminableMock) });
        emit IAdminable.TransferAdmin({ oldAdmin: admin, newAdmin: address(0) });

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
        emit IAdminable.TransferAdmin({ oldAdmin: admin, newAdmin: alice });

        // Transfer the admin.
        adminableMock.transferAdmin(alice);

        // It should set the new admin.
        address actualAdmin = adminableMock.admin();
        address expectedAdmin = alice;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }
}
