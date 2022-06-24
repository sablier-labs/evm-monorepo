// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__IsCancelable__StreamNonExistent is SablierV2LinearUnitTest {
    /// @dev it should return zero.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool actualCancelable = sablierV2Linear.isCancelable(nonStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }
}

contract StreamExistent {}

contract SablierV2Linear__IsCancelable__StreamCancelable is SablierV2LinearUnitTest, StreamExistent {
    /// @dev it should return false.
    function testIsCancelable__CancelableStream() external {
        uint256 daiStreamId = createDefaultDaiStream();
        bool actualCancelable = sablierV2Linear.isCancelable(daiStreamId);
        bool expectedCancelable = true;
        assertEq(actualCancelable, expectedCancelable);
    }
}

contract SablierV2Linear__IsCancelable___StreamNonCancelable is SablierV2LinearUnitTest, StreamExistent {
    /// @dev it should return true.
    function testIsCancelable__NonCancelableStream() external {
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();
        bool actualCancelable = sablierV2Linear.isCancelable(nonCancelableDaiStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }
}
