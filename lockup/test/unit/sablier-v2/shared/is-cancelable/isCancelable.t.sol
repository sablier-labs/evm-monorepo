// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract IsCancelable__Test is SharedTest {
    /// @dev it should return false.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool isCancelable = sablierV2.isCancelable(nonStreamId);
        assertFalse(isCancelable);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsCancelable__CancelableStream() external StreamExistent {
        uint256 streamId = createDefaultStream();
        bool isCancelable = sablierV2.isCancelable(streamId);
        assertTrue(isCancelable);
    }

    modifier NonCancelableStream() {
        _;
    }

    /// @dev it should return false.
    function testIsCancelable() external StreamExistent NonCancelableStream {
        uint256 streamId = createDefaultStreamNonCancelable();
        bool isCancelable = sablierV2.isCancelable(streamId);
        assertFalse(isCancelable);
    }
}
