// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract IsCancelable__Test is ProTest {
    /// @dev it should return false.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool isCancelable = pro.isCancelable(nonStreamId);
        assertFalse(isCancelable);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsCancelable__CancelableStream() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        bool isCancelable = pro.isCancelable(daiStreamId);
        assertTrue(isCancelable);
    }

    modifier NonCancelableStream() {
        _;
    }

    /// @dev it should return false.
    function testIsCancelable() external StreamExistent NonCancelableStream {
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();
        bool isCancelable = pro.isCancelable(nonCancelableDaiStreamId);
        assertFalse(isCancelable);
    }
}
