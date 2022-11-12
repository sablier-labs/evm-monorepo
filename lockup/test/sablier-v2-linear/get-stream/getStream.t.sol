// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";

import { SablierV2LinearBaseTest } from "../SablierV2LinearBaseTest.t.sol";

contract GetStream__Tests is SablierV2LinearBaseTest {
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
