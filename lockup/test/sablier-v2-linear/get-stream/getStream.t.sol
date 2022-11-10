// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetStream is SablierV2LinearUnitTest {
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
