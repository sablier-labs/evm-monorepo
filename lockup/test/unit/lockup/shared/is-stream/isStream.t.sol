// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract IsStream_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    function test_IsStream_Null() external {
        uint256 nullStreamId = 1729;
        bool isStream = lockup.isStream(nullStreamId);
        assertFalse(isStream, "isStream");
    }

    modifier whenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_IsStream() external whenNotNull {
        bool isStream = lockup.isStream(defaultStreamId);
        assertTrue(isStream, "isStream");
    }
}
