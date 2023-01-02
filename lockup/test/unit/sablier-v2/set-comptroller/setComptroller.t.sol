// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IOwnable } from "@prb/contracts/access/IOwnable.sol";

import { Events } from "src/libraries/Events.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { SablierV2Test } from "../SablierV2.t.sol";

contract SetComptroller__Test is SablierV2Test {
    /// @dev it should revert.
    function testCannotSetComptroller__CallerNotOwner(address eve) external {
        vm.assume(eve != users.owner);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable__CallerNotOwner.selector, users.owner, eve));
        sablierV2.setComptroller(ISablierV2Comptroller(eve));
    }

    modifier CallerOwner() {
        // Make the owner the caller in the rest of this test suite.
        changePrank(users.owner);
        _;
    }

    /// @dev it should re-set the comptroller.
    function testSetComptroller__SameComptroller() external CallerOwner {
        sablierV2.setComptroller(comptroller);
        address actualComptroller = address(sablierV2.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller);
    }

    /// @dev it should set the new comptroller.
    function testSetComptroller__NewComptroller() external CallerOwner {
        // Deploy new comptroller.
        ISablierV2Comptroller newComptroller = new SablierV2Comptroller();

        // Run the test.
        sablierV2.setComptroller(newComptroller);
        address actualComptroller = address(sablierV2.comptroller());
        address expectedComptroller = address(newComptroller);
        assertEq(actualComptroller, expectedComptroller);
    }
}
