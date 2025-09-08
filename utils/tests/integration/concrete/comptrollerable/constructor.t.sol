// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { ComptrollerableMock } from "src/mocks/ComptrollerableMock.sol";
import { ComptrollerWithoutMinimalInterfaceId } from "src/mocks/ComptrollerMock.sol";

import { Base_Test } from "../../../Base.t.sol";

contract Constructor_Comptrollerable_Concrete_Test is Base_Test {
    function test_RevertWhen_ComptrollerWithoutMinimalInterfaceId() external {
        address newComptrollerWithoutMinimalInterfaceId = address(new ComptrollerWithoutMinimalInterfaceId());

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Comptrollerable_UnsupportedInterfaceId.selector,
                address(0),
                address(newComptrollerWithoutMinimalInterfaceId),
                comptroller.MINIMAL_INTERFACE_ID()
            )
        );
        new ComptrollerableMock(newComptrollerWithoutMinimalInterfaceId);
    }

    function test_Constructor() external view whenComptrollerWithMinimalInterfaceId {
        // Assert the state variables.
        assertEq(address(comptrollerableMock.comptroller()), address(comptroller), "comptroller");
    }
}
