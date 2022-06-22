// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__UnitTest__GetRecipient is SablierV2ProUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetRecipient__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualRecipient = sablierV2Pro.getRecipient(nonStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev When the stream exists, it should return the correct recipient.
    function testGetRecipient() external {
        uint256 daiStreamId = createDefaultDaiStream();
        address actualRecipient = sablierV2Pro.getRecipient(daiStreamId);
        address expectedRecipient = daiStream.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }
}
