// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__GetCliffTime is SablierV2CliffUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetCliffTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualCliffTime = sablierV2Cliff.getCliffTime(nonStreamId);
        uint256 expectedCliffTime = 0;
        assertEq(actualCliffTime, expectedCliffTime);
    }

    /// @dev When the stream exists, it should return the correct cliff time.
    function testGetCliffTime() external {
        uint256 streamId = createDefaultStream();
        uint256 actualCliffTime = sablierV2Cliff.getCliffTime(streamId);
        uint256 expectedCliffTime = stream.cliffTime;
        assertEq(actualCliffTime, expectedCliffTime);
    }
}
