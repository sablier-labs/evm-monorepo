// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IAdminable } from "src/interfaces/IAdminable.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../../../Base.t.sol";

contract TransferAdmin_Adminable_Fuzz_Test is Base_Test {
    function testFuzz_RevertWhen_CallerNotAdmin(address eve) external {
        vm.assume(eve != address(0) && eve != admin);

        // Make Eve the caller in this test.
        setMsgSender(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, eve));
        adminableMock.transferAdmin(eve);
    }

    function testFuzz_TransferAdmin(address newAdmin) external whenCallerAdmin {
        vm.assume(newAdmin != address(0));

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(adminableMock) });
        emit IAdminable.TransferAdmin({ oldAdmin: admin, newAdmin: newAdmin });

        // Transfer the admin.
        adminableMock.transferAdmin(newAdmin);

        // Assert that the admin has been transferred.
        address actualAdmin = adminableMock.admin();
        address expectedAdmin = newAdmin;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }
}
