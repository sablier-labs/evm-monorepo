// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract IsEntity__Test is SharedTest {
    /// @dev it should return false.
    function testIsEntity__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool isEntity = sablierV2.isEntity(nonStreamId);
        assertFalse(isEntity);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsEntity() external StreamExistent {
        uint256 streamId = createDefaultStream();
        bool isEntity = sablierV2.isEntity(streamId);
        assertTrue(isEntity);
    }
}
