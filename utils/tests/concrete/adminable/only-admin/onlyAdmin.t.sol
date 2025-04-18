// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { Adminable_Unit_Concrete_Test } from "../Adminable.t.sol";

contract OnlyAdmin_Adminable_Unit_Concrete_Test is Adminable_Unit_Concrete_Test {
    function test_WhenCallerAdmin() external {
        // It should execute the function.
        adminableMock.restrictedToAdmin();
    }

    function test_RevertWhen_CallerNotAdmin() external whenCallerNotAdmin {
        setMsgSender(eve);

        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, eve));
        adminableMock.restrictedToAdmin();
    }
}
