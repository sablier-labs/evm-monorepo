// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__GetSender is SablierV2CliffUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetSender__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualSender = sablierV2Cliff.getSender(nonStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender);
    }

    /// @dev When the stream exists, it should return the correct sender.
    function testGetSender() external {
        uint256 streamId = createDefaultDaiStream();
        address actualSender = sablierV2Cliff.getSender(streamId);
        address expectedSender = daiStream.sender;
        assertEq(actualSender, expectedSender);
    }
}
