// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract IsCancelable__Test is SablierV2LinearTest {
    /// @dev it should return false.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool isCancelable = sablierV2Linear.isCancelable(nonStreamId);
        assertFalse(isCancelable);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsCancelable__CancelableStream() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        bool isCancelable = sablierV2Linear.isCancelable(defaultStreamId);
        assertTrue(isCancelable);
    }

    modifier NonCancelableStream() {
        _;
    }

    /// @dev it should return false.
    function testIsCancelable() external StreamExistent NonCancelableStream {
        uint256 streamId = createDefaultStreamNonCancelable();
        bool isCancelable = sablierV2Linear.isCancelable(streamId);
        assertFalse(isCancelable);
    }
}
