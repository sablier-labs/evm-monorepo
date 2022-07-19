// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__GetStream is SablierV2ProUnitTest {
    /// @dev it should return a zeroed out stream struct.
    function testGetStream__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(nonStreamId);
        ISablierV2Pro.Stream memory expectedStream;
        assertEq(actualStream, expectedStream);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the stream struct.
    function testGetStream() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        ISablierV2Pro.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }
}
