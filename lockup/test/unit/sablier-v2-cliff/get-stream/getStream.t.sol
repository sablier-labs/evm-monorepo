// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__GetStream is SablierV2CliffUnitTest {
    /// @dev When the stream does not exist, it should return a zeroed out stream struct.
    function testGetStream__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        ISablierV2Cliff.Stream memory actualStream = sablierV2Cliff.getStream(nonStreamId);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev When the stream exists, it should return the stream struct.
    function testGetStream() external {
        uint256 streamId = createDefaultDaiStream();
        ISablierV2Cliff.Stream memory actualStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }
}
