// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { LinearStream } from "src/types/Structs.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract GetStream_LinearTest is LinearTest {
    /// @dev it should return a zeroed out stream.
    function test_GetStream_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        LinearStream memory actualStream = linear.getStream(nonStreamId);
        LinearStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier streamExistent() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external streamExistent {
        uint256 streamId = createDefaultStream();
        LinearStream memory actualStream = linear.getStream(streamId);
        LinearStream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
