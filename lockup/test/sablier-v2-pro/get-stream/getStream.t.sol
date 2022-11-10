// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__GetStream is SablierV2ProUnitTest {
    /// @dev it should return a zeroed out stream struct.
    function testGetStream__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        DataTypes.ProStream memory actualStream = sablierV2Pro.getStream(nonStreamId);
        DataTypes.ProStream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the stream struct.
    function testGetStream() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        DataTypes.ProStream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        DataTypes.ProStream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }
}
