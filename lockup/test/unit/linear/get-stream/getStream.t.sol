// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract GetStream__Test is LinearTest {
    /// @dev it should return a zeroed out stream struct.
    function testGetStream__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        DataTypes.LinearStream memory actualStream = linear.getStream(nonStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the stream struct.
    function testGetStream() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        DataTypes.LinearStream memory actualStream = linear.getStream(defaultStreamId);
        DataTypes.LinearStream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
