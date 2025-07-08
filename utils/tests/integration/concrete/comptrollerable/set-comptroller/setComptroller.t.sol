// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { IComptrollerable } from "src/interfaces/IComptrollerable.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SetComptroller_Comptrollerable_Concrete_Test is Base_Test {
    ISablierComptroller internal newComptroller;

    function setUp() public override {
        super.setUp();

        // Deploy a new comptroller.
        newComptroller = ISablierComptroller(admin);
    }

    function test_RevertWhen_CallerNotCurrentComptroller() external {
        setMsgSender(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Comptrollerable_CallerNotComptroller.selector, comptroller, admin)
        );
        comptrollerableMock.setComptroller(newComptroller);
    }

    function test_RevertWhen_NewComptrollerZeroAddress() external whenCallerCurrentComptroller {
        vm.expectRevert(Errors.Comptrollerable_ZeroAddress.selector);
        comptrollerableMock.setComptroller(ISablierComptroller(address(0)));
    }

    function test_WhenNewComptrollerNotZeroAddress() external whenCallerCurrentComptroller {
        vm.expectEmit({ emitter: address(comptrollerableMock) });
        emit IComptrollerable.SetComptroller(newComptroller, comptroller);
        comptrollerableMock.setComptroller(newComptroller);
        assertEq(address(comptrollerableMock.comptroller()), address(newComptroller), "Comptroller not set correctly");
    }
}
