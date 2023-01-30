// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { Adminable_Fuzz_Test } from "../Adminable.t.sol";

contract TransferAdmin_Fuzz_Test is Adminable_Fuzz_Test {
    modifier callerAdmin() {
        _;
    }

    /// @dev it should emit a TransferAdmin event and set the new admin.
    function testFuzz_TransferAdmin(address newAdmin) external callerAdmin {
        vm.assume(newAdmin != address(0) && newAdmin != users.admin);

        // Expect a {TransferAdmin} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: false });
        emit Events.TransferAdmin({ oldAdmin: users.admin, newAdmin: newAdmin });

        // Transfer the admin.
        adminable.transferAdmin(newAdmin);

        // Assert that the admin was transferred.
        address actualAdmin = adminable.admin();
        address expectedAdmin = newAdmin;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }
}
