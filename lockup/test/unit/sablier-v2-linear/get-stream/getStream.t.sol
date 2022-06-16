// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__GetStream is SablierV2LinearUnitTest {
    /// @dev When the stream does not exist, it should return a zeroed out stream struct.
    function testGetStream__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(nonStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev When the stream exists, it should return the stream struct.
    function testGetStream() external {
        uint256 streamId = createDefaultStream();
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(streamId);
        ISablierV2Linear.Stream memory expectedStream = stream;
        assertEq(actualStream, expectedStream);
    }
}
