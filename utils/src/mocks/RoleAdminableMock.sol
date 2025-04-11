// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { RoleAdminable } from "src/RoleAdminable.sol";

contract RoleAdminableMock is RoleAdminable {
    constructor(address initialAdmin) RoleAdminable(initialAdmin) { }

    /// @dev A mock function to test the `onlyRole` modifier.
    function restrictedToRole() public onlyRole(FEE_COLLECTOR_ROLE) { }
}
