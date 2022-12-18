// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract GetStream__Test is SablierV2LinearTest {
    /// @dev it should return a zeroed out stream struct.
    function testGetStream__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(nonStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the stream struct.
    function testGetStream() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }
}
