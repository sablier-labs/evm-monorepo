// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Adminable } from "src/interfaces/ISablierV2Adminable.sol";

import { Unit_Test } from "../Unit.t.sol";

/// @title Adminable_Unit_Test
/// @notice Common testing logic needed across {SablierV2Adminable} unit tests.
abstract contract Adminable_Unit_Test is Unit_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Adminable internal adminable;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Unit_Test.setUp();

        // Cast the linear contract as the {ISablierV2Adminable} contract.
        adminable = ISablierV2Adminable(address(linear));
    }
}
