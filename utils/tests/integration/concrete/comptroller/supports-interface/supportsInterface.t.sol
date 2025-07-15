// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SupportsInterface_Comptroller_Concrete_Test is Base_Test {
    bytes4 internal minimalInterfaceId;
    bytes4 internal erc165InterfaceId;

    function setUp() public override {
        super.setUp();

        minimalInterfaceId = comptroller.MINIMAL_INTERFACE_ID();
        erc165InterfaceId = type(IERC165).interfaceId;
    }

    function test_WhenInputMatchesNone(bytes4 interfaceId) external view {
        vm.assume(interfaceId != erc165InterfaceId && interfaceId != minimalInterfaceId);

        // It should return false.
        assertFalse(comptroller.supportsInterface(interfaceId), "supportsInterface");
    }

    function test_WhenInputMatchesOnlyOneFunctionSelector() external view {
        bytes4 interfaceId = ISablierComptroller.execute.selector;

        // It should return false.
        assertFalse(comptroller.supportsInterface(interfaceId), "supportsInterface");
    }

    function test_WhenInputMatchesIERC165InterfaceId() external view {
        // It should return true.
        assertTrue(comptroller.supportsInterface(erc165InterfaceId), "supportsInterface");
    }

    function test_WhenInputMatchesMinimalInterfaceId() external view {
        // It should return true.
        assertTrue(comptroller.supportsInterface(minimalInterfaceId), "supportsInterface");
    }
}
