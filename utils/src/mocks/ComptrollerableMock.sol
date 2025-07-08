// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Comptrollerable } from "../../src/Comptrollerable.sol";

contract ComptrollerableMock is Comptrollerable {
    constructor(address initialComptroller) Comptrollerable(initialComptroller) { }

    /// @dev A mock function to test the `onlyComptroller` modifier.
    function restrictedToComptroller() public onlyComptroller { }
}
