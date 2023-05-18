// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Adminable_Integration_Shared_Test } from "../../../shared/adminable/Adminable.t.sol";

contract TransferAdmin_Integration_Basic_Test is Adminable_Integration_Shared_Test {
    function testFuzz_RevertWhen_CallerNotAdmin(address eve) external {
        vm.assume(eve != address(0) && eve != users.admin);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, eve));
        adminable.transferAdmin(eve);
    }

    modifier whenCallerAdmin() {
        _;
    }

    function test_TransferAdmin_SameAdmin() external whenCallerAdmin {
        // Expect a {TransferAdmin} event to be emitted.
        vm.expectEmit({ emitter: address(adminable) });
        emit TransferAdmin({ oldAdmin: users.admin, newAdmin: users.admin });

        // Transfer the admin.
        adminable.transferAdmin(users.admin);

        // Assert that the admin remained the same.
        address actualAdmin = adminable.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }

    function test_TransferAdmin_ZeroAddress() external whenCallerAdmin {
        // Expect a {TransferAdmin} event to be emitted.
        vm.expectEmit({ emitter: address(adminable) });
        emit TransferAdmin({ oldAdmin: users.admin, newAdmin: address(0) });

        // Transfer the admin.
        adminable.transferAdmin(address(0));

        // Assert that the admin has been transferred.
        address actualAdmin = adminable.admin();
        address expectedAdmin = address(0);
        assertEq(actualAdmin, expectedAdmin, "admin");
    }

    modifier whenNotZeroAddress() {
        _;
    }

    function test_TransferAdmin_NewAdmin() external whenCallerAdmin whenNotZeroAddress {
        // Expect a {TransferAdmin} event to be emitted.
        vm.expectEmit({ emitter: address(adminable) });
        emit TransferAdmin({ oldAdmin: users.admin, newAdmin: users.alice });

        // Transfer the admin.
        adminable.transferAdmin(users.alice);

        // Assert that the admin has been transferred.
        address actualAdmin = adminable.admin();
        address expectedAdmin = users.alice;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }
}
