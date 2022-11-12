// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearBaseTest } from "../SablierV2LinearBaseTest.t.sol";

contract GetSender__Tests is SablierV2LinearBaseTest {
    /// @dev it should return zero.
    function testGetSender__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualSender = sablierV2Linear.getSender(nonStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct sender.
    function testGetSender() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        address actualSender = sablierV2Linear.getSender(daiStreamId);
        address expectedSender = daiStream.sender;
        assertEq(actualSender, expectedSender);
    }
}
