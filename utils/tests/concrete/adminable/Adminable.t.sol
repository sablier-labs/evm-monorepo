// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { AdminableMock } from "src/mocks/AdminableMock.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract Adminable_Unit_Concrete_Test is Unit_Test {
    AdminableMock internal adminableMock;

    function setUp() public override {
        Unit_Test.setUp();

        adminableMock = new AdminableMock(admin);
        setMsgSender(admin);
    }

    function test_Constructor() public view {
        // Assert the state variables.
        assertEq(adminableMock.admin(), admin, "admin");
    }
}
