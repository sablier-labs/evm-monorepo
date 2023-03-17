// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetStream_Linear_Unit_Test is Linear_Unit_Test {
    /// @dev it should return a zeroed out stream.
    function test_GetStream_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupLinear.Stream memory actualStream = linear.getStream(nullStreamId);
        LockupLinear.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        LockupLinear.Stream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
