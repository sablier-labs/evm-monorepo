// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearBaseTest } from "../SablierV2LinearBaseTest.t.sol";

contract GetCliffTime__Tests is SablierV2LinearBaseTest {
    /// @dev it should return zero.
    function testGetCliffTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualCliffTime = sablierV2Linear.getCliffTime(nonStreamId);
        uint256 expectedCliffTime = 0;
        assertEq(actualCliffTime, expectedCliffTime);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct cliff time.
    function testGetCliffTime() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256 actualCliffTime = sablierV2Linear.getCliffTime(daiStreamId);
        uint256 expectedCliffTime = daiStream.cliffTime;
        assertEq(actualCliffTime, expectedCliffTime);
    }
}
