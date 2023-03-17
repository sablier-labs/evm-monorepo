// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IAdminable } from "src/interfaces/IAdminable.sol";

import { Unit_Test } from "../Unit.t.sol";

/// @title Adminable_Unit_Test
/// @notice Common testing logic needed across {Adminable} unit tests.
abstract contract Adminable_Unit_Test is Unit_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IAdminable internal adminable;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Unit_Test.setUp();

        // Cast the linear contract as the {IAdminable} contract.
        adminable = IAdminable(address(linear));
    }
}
