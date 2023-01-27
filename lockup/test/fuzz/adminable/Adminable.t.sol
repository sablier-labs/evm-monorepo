// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Adminable } from "src/interfaces/ISablierV2Adminable.sol";

import { Fuzz_Test } from "../Fuzz.t.sol";

/// @title Adminable_Fuzz_Test
/// @notice Common testing logic needed across {SablierV2Adminable} fuzz tests.
abstract contract Adminable_Fuzz_Test is Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Adminable internal adminable;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fuzz_Test.setUp();

        // Cast the linear contract as {ISablierV2Adminable}.
        adminable = ISablierV2Adminable(address(linear));
    }
}
