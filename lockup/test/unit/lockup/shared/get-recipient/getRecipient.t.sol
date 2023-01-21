// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Shared_Lockup_Unit_Test } from "../SharedTest.t.sol";

abstract contract GetRecipient_Unit_Test is Shared_Lockup_Unit_Test {
    /// @dev it should return zero.
    function test_GetRecipient_StreamNull() external {
        uint256 nullStreamId = 1729;
        address actualRecipient = lockup.getRecipient(nullStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct recipient.
    function test_GetRecipient() external streamNonNull {
        uint256 streamId = createDefaultStream();
        address actualRecipient = lockup.getRecipient(streamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
