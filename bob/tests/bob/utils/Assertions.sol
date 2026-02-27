// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { PRBMathAssertions } from "@prb/math/test/utils/Assertions.sol";

import { Bob } from "src/types/Bob.sol";

abstract contract Assertions is PRBMathAssertions {
    /// @dev Compares two {Bob.Status} enum values.
    function assertEq(Bob.Status a, Bob.Status b) internal pure {
        assertEq(uint256(a), uint256(b), "status");
    }
}
