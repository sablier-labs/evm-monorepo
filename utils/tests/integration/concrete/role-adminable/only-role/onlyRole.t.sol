// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { Base_Test } from "../../../../Base.t.sol";

contract OnlyRole_RoleAdminable_Concrete_Test is Base_Test {
    function test_WhenCallerAdmin() external {
        // It should execute the function.
        roleAdminableMock.restrictedToRole();
    }

    function test_RevertWhen_CallerNotHaveRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);

        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_COLLECTOR_ROLE));
        roleAdminableMock.restrictedToRole();
    }

    function test_WhenCallerHasRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // It should execute the function.
        roleAdminableMock.restrictedToRole();
    }
}
