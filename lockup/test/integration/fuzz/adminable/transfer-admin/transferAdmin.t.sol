// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Adminable_Integration_Shared_Test } from "../../../shared/adminable/Adminable.t.sol";

contract TransferAdmin_Integration_Fuzz_Test is Adminable_Integration_Shared_Test {
    modifier whenCallerAdmin() {
        _;
    }

    function testFuzz_TransferAdmin(address newAdmin) external whenCallerAdmin {
        vm.assume(newAdmin != address(0));

        // Expect a {TransferAdmin} event to be emitted.
        vm.expectEmit({ emitter: address(adminable) });
        emit TransferAdmin({ oldAdmin: users.admin, newAdmin: newAdmin });

        // Transfer the admin.
        adminable.transferAdmin(newAdmin);

        // Assert that the admin has been transferred.
        address actualAdmin = adminable.admin();
        address expectedAdmin = newAdmin;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }
}
