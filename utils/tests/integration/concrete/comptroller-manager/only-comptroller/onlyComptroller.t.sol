// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { Base_Test } from "../../../../Base.t.sol";

contract OnlyComptroller_ComptrollerManager_Concrete_Test is Base_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ComptrollerManager_CallerNotComptroller.selector, comptroller, admin)
        );
        comptrollerManager.restrictedToComptroller();
    }

    function test_WhenCallerComptroller() external {
        setMsgSender(address(comptroller));

        // It should execute the function.
        comptrollerManager.restrictedToComptroller();
    }
}
