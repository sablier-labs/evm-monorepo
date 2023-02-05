// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { Fuzz_Test } from "../Fuzz.t.sol";

/// @title Comptroller_Fuzz_Test
/// @notice Dummy contract only needed for providing naming context in the test traces.
abstract contract Comptroller_Fuzz_Test is Fuzz_Test {
    function setUp() public virtual override {
        Fuzz_Test.setUp();
    }
}
