// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdInvariant } from "forge-std/src/StdInvariant.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all invariant tests.
abstract contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(lockupDynamic));
        excludeSender(address(lockupLinear));
    }
}
