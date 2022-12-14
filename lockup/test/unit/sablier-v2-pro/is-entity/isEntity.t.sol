// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract IsEntity__Test is SablierV2ProTest {
    /// @dev it should return false.
    function testIsEntity__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool isEntity = sablierV2Pro.isEntity(nonStreamId);
        assertFalse(isEntity);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsEntity() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        bool isEntity = sablierV2Pro.isEntity(daiStreamId);
        assertTrue(isEntity);
    }
}
