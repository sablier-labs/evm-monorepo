// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetSender__Test is SharedTest {
    /// @dev it should return zero.
    function testGetSender__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualSender = sablierV2.getSender(nonStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct sender.
    function testGetSender() external StreamExistent {
        uint256 streamId = createDefaultStream();
        address actualSender = sablierV2.getSender(streamId);
        address expectedSender = users.sender;
        assertEq(actualSender, expectedSender);
    }
}
