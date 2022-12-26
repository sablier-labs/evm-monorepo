// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract IsEntity__Test is ProTest {
    /// @dev it should return false.
    function testIsEntity__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool isEntity = pro.isEntity(nonStreamId);
        assertFalse(isEntity);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsEntity() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        bool isEntity = pro.isEntity(defaultStreamId);
        assertTrue(isEntity);
    }
}
