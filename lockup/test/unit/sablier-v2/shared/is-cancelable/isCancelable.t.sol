// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract IsCancelable_Test is SharedTest {
    /// @dev it should return false.
    function test_IsCancelable_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool isCancelable = sablierV2.isCancelable(nonStreamId);
        assertFalse(isCancelable);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function test_IsCancelable_CancelableStream() external StreamExistent {
        uint256 streamId = createDefaultStream();
        bool isCancelable = sablierV2.isCancelable(streamId);
        assertTrue(isCancelable);
    }

    modifier NonCancelableStream() {
        _;
    }

    /// @dev it should return false.
    function test_IsCancelable() external StreamExistent NonCancelableStream {
        uint256 streamId = createDefaultStreamNonCancelable();
        bool isCancelable = sablierV2.isCancelable(streamId);
        assertFalse(isCancelable);
    }
}
