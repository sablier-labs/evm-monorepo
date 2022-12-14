// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract IsEntity__Test is SablierV2ProTest {
    /// @dev it should return false.
    function testIsEntity__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool actualIsEntity = sablierV2Pro.isEntity(nonStreamId);
        bool expectedIsEntity = false;
        assertEq(actualIsEntity, expectedIsEntity);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsEntity() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        bool actualIsEntity = sablierV2Pro.isEntity(daiStreamId);
        bool expectedIsEntity = true;
        assertEq(actualIsEntity, expectedIsEntity);
    }
}
