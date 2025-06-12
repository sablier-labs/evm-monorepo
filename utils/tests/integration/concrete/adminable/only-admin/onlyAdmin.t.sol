// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { Base_Test } from "../../../../Base.t.sol";

contract OnlyAdmin_Adminable_Concrete_Test is Base_Test {
    function test_WhenCallerAdmin() external {
        // It should execute the function.
        adminable.restrictedToAdmin();
    }

    function test_RevertWhen_CallerNotAdmin() external whenCallerNotAdmin {
        setMsgSender(users.eve);

        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.eve));
        adminable.restrictedToAdmin();
    }
}
