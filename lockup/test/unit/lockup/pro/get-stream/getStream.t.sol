// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { LockupProStream } from "src/types/Structs.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract GetStream_Pro_Unit_Test is Pro_Unit_Test {
    /// @dev it should return a zeroed out stream.
    function test_GetStream_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupProStream memory actualStream = pro.getStream(nullStreamId);
        LockupProStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external streamNonNull {
        uint256 streamId = createDefaultStream();
        LockupProStream memory actualStream = pro.getStream(streamId);
        LockupProStream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
