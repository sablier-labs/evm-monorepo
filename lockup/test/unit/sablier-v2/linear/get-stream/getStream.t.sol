// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { LinearStream } from "src/types/Structs.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract GetStream__LinearTest is LinearTest {
    /// @dev it should return a zeroed out stream.
    function testGetStream__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        LinearStream memory actualStream = linear.getStream(nonStreamId);
        LinearStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the stream.
    function testGetStream() external StreamExistent {
        uint256 streamId = createDefaultStream();
        LinearStream memory actualStream = linear.getStream(streamId);
        LinearStream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
