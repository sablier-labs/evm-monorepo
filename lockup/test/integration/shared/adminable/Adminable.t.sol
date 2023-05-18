// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IAdminable } from "src/interfaces/IAdminable.sol";

import { Integration_Test } from "../../Integration.t.sol";

/// @title Adminable_Integration_Shared_Test
/// @notice Common testing logic needed across {Adminable} integration tests.
abstract contract Adminable_Integration_Shared_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IAdminable internal adminable;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the linear contract as {IAdminable}.
        adminable = IAdminable(address(linear));
    }
}
