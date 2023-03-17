// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupPro } from "src/types/DataTypes.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract GetStream_Pro_Unit_Test is Pro_Unit_Test {
    /// @dev it should return a zeroed out stream.
    function test_GetStream_StreamNull() external {
        uint256 nullStreamId = 1729;
        LockupPro.Stream memory actualStream = pro.getStream(nullStreamId);
        LockupPro.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupPro.Stream memory actualStream = pro.getStream(streamId);
        LockupPro.Stream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
