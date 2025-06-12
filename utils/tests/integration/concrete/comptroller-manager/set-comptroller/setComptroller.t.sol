// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { IComptrollerManager } from "src/interfaces/IComptrollerManager.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SetComptroller_ComptrollerManager_Concrete_Test is Base_Test {
    ISablierComptroller internal newComptroller;

    function setUp() public override {
        super.setUp();

        // Deploy a new comptroller.
        newComptroller = ISablierComptroller(admin);
    }

    function test_RevertWhen_CallerNotCurrentComptroller() external {
        setMsgSender(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ComptrollerManager_CallerNotComptroller.selector, comptroller, admin)
        );
        comptrollerManagerMock.setComptroller(newComptroller);
    }

    function test_RevertWhen_NewComptrollerZeroAddress() external whenCallerCurrentComptroller {
        vm.expectRevert(Errors.ComptrollerManager_ZeroAddress.selector);
        comptrollerManagerMock.setComptroller(ISablierComptroller(address(0)));
    }

    function test_WhenNewComptrollerNotZeroAddress() external whenCallerCurrentComptroller {
        vm.expectEmit({ emitter: address(comptrollerManagerMock) });
        emit IComptrollerManager.SetComptroller(newComptroller, comptroller);
        comptrollerManagerMock.setComptroller(newComptroller);
        assertEq(
            address(comptrollerManagerMock.comptroller()), address(newComptroller), "Comptroller not set correctly"
        );
    }
}
