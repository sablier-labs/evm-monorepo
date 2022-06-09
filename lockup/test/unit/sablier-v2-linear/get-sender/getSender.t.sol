// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetSender__UnitTest is SablierV2LinearUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetSender__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualSender = sablierV2Linear.getSender(nonStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender);
    }

    /// @dev When the stream exists, it should return the correct sender.
    function testGetSender() external {
        uint256 streamId = createDefaultStream();
        address actualSender = sablierV2Linear.getSender(streamId);
        address expectedSender = stream.sender;
        assertEq(actualSender, expectedSender);
    }
}
