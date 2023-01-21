// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Shared_Lockup_Unit_Test } from "../SharedTest.t.sol";

abstract contract GetSender_Unit_Test is Shared_Lockup_Unit_Test {
    /// @dev it should return zero.
    function test_GetSender_StreamNull() external {
        uint256 nullStreamId = 1729;
        address actualSender = lockup.getSender(nullStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender, "sender");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct sender.
    function test_GetSender() external streamNonNull {
        uint256 streamId = createDefaultStream();
        address actualSender = lockup.getSender(streamId);
        address expectedSender = users.sender;
        assertEq(actualSender, expectedSender, "sender");
    }
}
