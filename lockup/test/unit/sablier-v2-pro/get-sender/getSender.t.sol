// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__GetSender__StreamNotExistent is SablierV2ProUnitTest {
    /// @dev it should return zero.
    function testGetSender__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualSender = sablierV2Pro.getSender(nonStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender);
    }
}

contract StreamExistent {}

contract SablierV2Pro__GetSender is SablierV2ProUnitTest, StreamExistent {
    /// @dev it should return the correct sender.
    function testGetSender() external {
        uint256 daiStreamId = createDefaultDaiStream();
        address actualSender = sablierV2Pro.getSender(daiStreamId);
        address expectedSender = daiStream.sender;
        assertEq(actualSender, expectedSender);
    }
}
