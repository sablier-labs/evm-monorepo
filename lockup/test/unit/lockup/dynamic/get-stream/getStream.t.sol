// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract GetStream_Dynamic_Unit_Test is Dynamic_Unit_Test {
    /// @dev it should return a zeroed out stream.
    function test_GetStream_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupDynamic.Stream memory actualStream = dynamic.getStream(nullStreamId);
        LockupDynamic.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
