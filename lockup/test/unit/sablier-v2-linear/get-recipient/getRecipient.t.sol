// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetRecipient__StreamNonExistent is SablierV2LinearUnitTest {
    /// @dev it should return zero.
    function testGetRecipient() external {
        uint256 nonStreamId = 1729;
        address actualRecipient = sablierV2Linear.getRecipient(nonStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }
}

contract StreamExistent {}

contract SablierV2Linear__GetRecipient is SablierV2LinearUnitTest, StreamExistent {
    /// @dev it should return the correct recipient.
    function testGetRecipient() external {
        uint256 daiStreamId = createDefaultDaiStream();
        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = daiStream.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }
}
