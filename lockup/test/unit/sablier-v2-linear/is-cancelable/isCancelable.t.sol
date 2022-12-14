// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract IsCancelable__Test is SablierV2LinearTest {
    /// @dev it should return false.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool actualIsCancelable = sablierV2Linear.isCancelable(nonStreamId);
        bool expectedIsCancelable = false;
        assertEq(actualIsCancelable, expectedIsCancelable);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsCancelable__CancelableStream() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        bool actualIsCancelable = sablierV2Linear.isCancelable(daiStreamId);
        bool expectedIsCancelable = true;
        assertEq(actualIsCancelable, expectedIsCancelable);
    }

    modifier NonCancelableStream() {
        _;
    }

    /// @dev it should return false.
    function testIsCancelable() external StreamExistent NonCancelableStream {
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();
        bool actualIsCancelable = sablierV2Linear.isCancelable(nonCancelableDaiStreamId);
        bool expectedIsCancelable = false;
        assertEq(actualIsCancelable, expectedIsCancelable);
    }
}
