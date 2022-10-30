// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetRecipient is SablierV2LinearUnitTest {
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
        uint256 daiStreamId = createDefaultDaiStream();
        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }
}
