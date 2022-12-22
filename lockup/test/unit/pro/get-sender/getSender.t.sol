// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract GetSender__Test is ProTest {
    /// @dev it should return zero.
    function testGetSender__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        address actualSender = pro.getSender(nonStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct sender.
    function testGetSender() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        address actualSender = pro.getSender(daiStreamId);
        address expectedSender = daiStream.sender;
        assertEq(actualSender, expectedSender);
    }
}
