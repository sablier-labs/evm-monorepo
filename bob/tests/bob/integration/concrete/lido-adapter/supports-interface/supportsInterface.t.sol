// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SupportsInterface_LidoAdapter_Integration_Concrete_Test is Integration_Test {
    function test_WhenInputMatchesNone() external view {
        // It should return false.
        assertFalse(adapter.supportsInterface(0xdeadbeef), "random");
    }

    function test_WhenInputMatchesIERC165InterfaceId() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(type(IERC165).interfaceId), "IERC165");
    }

    function test_WhenInputMatchesISablierBobAdapterInterfaceId() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(type(ISablierBobAdapter).interfaceId), "ISablierBobAdapter");
    }

    function test_WhenInputMatchesISablierLidoAdapterInterfaceId() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(type(ISablierLidoAdapter).interfaceId), "ISablierLidoAdapter");
    }
}
