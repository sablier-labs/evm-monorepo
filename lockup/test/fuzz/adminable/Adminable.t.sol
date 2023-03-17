// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IAdminable } from "src/interfaces/IAdminable.sol";

import { Fuzz_Test } from "../Fuzz.t.sol";

/// @title Adminable_Fuzz_Test
/// @notice Common testing logic needed across {Adminable} fuzz tests.
abstract contract Adminable_Fuzz_Test is Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IAdminable internal adminable;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fuzz_Test.setUp();

        // Cast the linear contract as {IAdminable}.
        adminable = IAdminable(address(linear));
    }
}
