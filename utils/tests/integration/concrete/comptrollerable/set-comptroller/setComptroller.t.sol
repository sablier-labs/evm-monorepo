// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IComptrollerable } from "src/interfaces/IComptrollerable.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ComptrollerWithoutMinimalInterfaceId } from "src/mocks/ComptrollerMock.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SetComptroller_Comptrollerable_Concrete_Test is Base_Test {
    ISablierComptroller internal newComptroller;

    function setUp() public override {
        super.setUp();

        // Deploy a new comptroller.
        newComptroller = new SablierComptroller(admin);
    }

    function test_RevertWhen_CallerNotCurrentComptroller() external {
        setMsgSender(admin);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Comptrollerable_CallerNotComptroller.selector, comptroller, admin)
        );
        comptrollerableMock.setComptroller(newComptroller);
    }

    function test_RevertWhen_NewComptrollerWithoutMinimalInterfaceId() external whenCallerCurrentComptroller {
        address newComptrollerWithoutMinimalInterfaceId = address(new ComptrollerWithoutMinimalInterfaceId());

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Comptrollerable_UnsupportedInterfaceId.selector,
                comptroller,
                newComptrollerWithoutMinimalInterfaceId,
                comptroller.MINIMAL_INTERFACE_ID()
            )
        );
        comptrollerableMock.setComptroller(ISablierComptroller(newComptrollerWithoutMinimalInterfaceId));
    }

    function test_WhenNewComptrollerWithMinimalInterfaceId() external whenCallerCurrentComptroller {
        vm.expectEmit({ emitter: address(comptrollerableMock) });
        emit IComptrollerable.SetComptroller(comptroller, newComptroller);
        comptrollerableMock.setComptroller(newComptroller);
        assertEq(address(comptrollerableMock.comptroller()), address(newComptroller), "Comptroller not set correctly");
    }
}
