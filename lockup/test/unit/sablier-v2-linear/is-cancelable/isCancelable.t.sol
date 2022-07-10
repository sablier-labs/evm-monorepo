// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__IsCancelable is SablierV2LinearUnitTest {
    /// @dev it should return zero.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool actualCancelable = sablierV2Linear.isCancelable(nonStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsCancelable__CancelableStream() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        bool actualCancelable = sablierV2Linear.isCancelable(daiStreamId);
        bool expectedCancelable = true;
        assertEq(actualCancelable, expectedCancelable);
    }

    /// @dev it should return false.
    function testIsCancelables__NonCancelableStream() external StreamExistent {
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();
        bool actualCancelable = sablierV2Linear.isCancelable(nonCancelableDaiStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }
}
