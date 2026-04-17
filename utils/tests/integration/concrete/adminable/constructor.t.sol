// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Base_Test } from "../../../Base.t.sol";

contract Constructor_Integration_Concrete_Test is Base_Test {
    function test_Constructor() public view {
        // It should set the state variables.
        assertEq(adminableMock.admin(), admin, "admin");
    }
}
