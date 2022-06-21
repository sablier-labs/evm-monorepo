// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__GetRecipient is SablierV2LinearUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetRecipient__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualRecipient = sablierV2Linear.getRecipient(nonStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev When the stream exists, it should return the correct recipient.
    function testGetRecipient() external {
        uint256 streamId = createDefaultDaiStream();
        address actualRecipient = sablierV2Linear.getRecipient(streamId);
        address expectedRecipient = daiStream.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }
}
