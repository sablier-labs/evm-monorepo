// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetCliffTime__StreamNonExistent is SablierV2LinearUnitTest {
    /// @dev it should return zero.
    function testGetCliffTime() external {
        uint256 nonStreamId = 1729;
        uint256 actualCliffTime = sablierV2Linear.getCliffTime(nonStreamId);
        uint256 expectedCliffTime = 0;
        assertEq(actualCliffTime, expectedCliffTime);
    }
}

contract StreamExistent {}

contract SablierV2Linear__GetCliffTime is SablierV2LinearUnitTest, StreamExistent {
    /// @dev it should return the correct cliff time.
    function testGetCliffTime() external {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256 actualCliffTime = sablierV2Linear.getCliffTime(daiStreamId);
        uint256 expectedCliffTime = daiStream.cliffTime;
        assertEq(actualCliffTime, expectedCliffTime);
    }
}
