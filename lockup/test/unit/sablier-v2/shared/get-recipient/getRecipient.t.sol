// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetRecipient_Test is SharedTest {
    /// @dev it should return zero.
    function test_GetRecipient_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualRecipient = sablierV2.getRecipient(nonStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct recipient.
    function test_GetRecipient() external StreamExistent {
        uint256 streamId = createDefaultStream();
        address actualRecipient = sablierV2.getRecipient(streamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }
}
