// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { LockupLinearStream } from "src/types/Structs.sol";

import { Linear_Test } from "../Linear.t.sol";

contract GetStream_Linear_Test is Linear_Test {
    /// @dev it should return a zeroed out stream.
    function test_GetStream_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupLinearStream memory actualStream = linear.getStream(nullStreamId);
        LockupLinearStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external streamNonNull {
        uint256 streamId = createDefaultStream();
        LockupLinearStream memory actualStream = linear.getStream(streamId);
        LockupLinearStream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
