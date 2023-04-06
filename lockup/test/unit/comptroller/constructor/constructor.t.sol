// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract Constructor_Comptroller_Unit_Test is Comptroller_Unit_Test {
    function test_Constructor() external {
        // Expect a {TransferEvent} to be emitted.
        vm.expectEmit();
        emit TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the comptroller contract.
        SablierV2Comptroller constructedComptroller = new SablierV2Comptroller({ initialAdmin: users.admin });

        // Assert that the admin has been initialized.
        address actualAdmin = constructedComptroller.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }
}
