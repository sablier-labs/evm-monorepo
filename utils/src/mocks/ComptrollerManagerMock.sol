// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ComptrollerManager } from "../../src/ComptrollerManager.sol";

contract ComptrollerManagerMock is ComptrollerManager {
    constructor(address initialComptroller) ComptrollerManager(initialComptroller) { }

    /// @dev A mock function to test the `onlyComptroller` modifier.
    function restrictedToComptroller() public onlyComptroller { }
}
