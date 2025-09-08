// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Base_Test } from "../../../Base.t.sol";

contract Constructor_Adminable_Concrete_Test is Base_Test {
    function test_Constructor() public view {
        // Assert the state variables.
        assertEq(adminableMock.admin(), admin, "admin");
    }
}
