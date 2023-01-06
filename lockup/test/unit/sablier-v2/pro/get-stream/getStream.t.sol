// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ProStream } from "src/types/Structs.sol";

import { ProTest } from "../ProTest.t.sol";

contract GetStream_ProTest is ProTest {
    /// @dev it should return a zeroed out stream.
    function test_GetStream_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        ProStream memory actualStream = pro.getStream(nonStreamId);
        ProStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external StreamExistent {
        uint256 streamId = createDefaultStream();
        ProStream memory actualStream = pro.getStream(streamId);
        ProStream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
