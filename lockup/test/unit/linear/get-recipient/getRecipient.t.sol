// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract GetRecipient__Test is SablierV2LinearTest {
    /// @dev it should return zero.
    function testGetRecipient__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualRecipient = sablierV2Linear.getRecipient(nonStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct recipient.
    function testGetRecipient() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        address actualRecipient = sablierV2Linear.getRecipient(defaultStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }
}
