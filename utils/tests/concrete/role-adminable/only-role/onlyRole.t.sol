// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { RoleAdminable_Unit_Concrete_Test } from "../RoleAdminable.t.sol";

contract OnlyRole_RoleAdminable_Unit_Concrete_Test is RoleAdminable_Unit_Concrete_Test {
    function test_WhenCallerAdmin() external {
        // It should execute the function.
        roleAdminableMock.restrictedToRole();
    }

    function test_RevertWhen_CallerNotHaveRole() external whenCallerNotAdmin {
        setMsgSender(eve);

        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, eve, FEE_COLLECTOR_ROLE));
        roleAdminableMock.restrictedToRole();
    }

    function test_WhenCallerHasRole() external whenCallerNotAdmin {
        setMsgSender(accountant);

        // It should execute the function.
        roleAdminableMock.restrictedToRole();
    }
}
