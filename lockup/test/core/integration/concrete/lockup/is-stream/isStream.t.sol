// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsStream_Integration_Concrete_Test is Integration_Test {
    function test_GivenNull() external view {
        uint256 nullStreamId = 1729;
        bool isStream = lockup.isStream(nullStreamId);
        assertFalse(isStream, "isStream");
    }

    function test_GivenNotNull() external view {
        bool isStream = lockup.isStream(defaultStreamId);
        assertTrue(isStream, "isStream");
    }
}
