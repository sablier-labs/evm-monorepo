// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__GetRecipient__StreamNonExistent is SablierV2ProUnitTest {
    /// @dev it should return zero.
    function testGetRecipient() external {
        uint256 nonStreamId = 1729;
        address actualRecipient = sablierV2Pro.getRecipient(nonStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }
}

contract StreamExistent {}

contract SablierV2Pro__GetRecipient is SablierV2ProUnitTest, StreamExistent {
    /// @dev it should return the correct recipient.
    function testGetRecipient() external {
        uint256 daiStreamId = createDefaultDaiStream();
        address actualRecipient = sablierV2Pro.getRecipient(daiStreamId);
        address expectedRecipient = daiStream.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }
}
