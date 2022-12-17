// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IOwnable } from "@prb/contracts/access/IOwnable.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract SetFee__Test is SablierV2LinearTest {
    /// @dev it should revert.
    function testCannotSetFee__CallerNotOwner() external {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        // vm.expectRevert(IOwnable.Ownable__CallerNotOwner());
    }
}
