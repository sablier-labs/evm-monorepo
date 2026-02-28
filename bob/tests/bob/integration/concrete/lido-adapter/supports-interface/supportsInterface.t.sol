// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SupportsInterface_Integration_Concrete_Test is Integration_Test {
    function test_WhenQueryingISablierBobAdapterInterface() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(type(ISablierBobAdapter).interfaceId), "ISablierBobAdapter");
    }

    function test_WhenQueryingISablierLidoAdapterInterface() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(type(ISablierLidoAdapter).interfaceId), "ISablierLidoAdapter");
    }

    function test_WhenQueryingIERC165Interface() external view {
        // It should return true.
        assertTrue(adapter.supportsInterface(0x01ffc9a7), "IERC165");
    }

    function test_WhenQueryingInvalidInterface() external view {
        // It should return false.
        assertFalse(adapter.supportsInterface(0xdeadbeef), "random");
    }
}
