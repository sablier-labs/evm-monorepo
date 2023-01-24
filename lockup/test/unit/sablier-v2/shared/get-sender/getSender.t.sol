// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetSender_Test is SharedTest {
    /// @dev it should return zero.
    function test_GetSender_StreamNull() external {
        uint256 nullStreamId = 1729;
        address actualSender = sablierV2.getSender(nullStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct sender.
    function test_GetSender() external streamNonNull {
        uint256 streamId = createDefaultStream();
        address actualSender = sablierV2.getSender(streamId);
        address expectedSender = users.sender;
        assertEq(actualSender, expectedSender);
    }
}
