// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__IsCancelable__StreamNonExistent is SablierV2ProUnitTest {
    /// @dev it should return zero.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool actualCancelable = sablierV2Pro.isCancelable(nonStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }
}

contract StreamExistent {}

contract SablierV2Pro__IsCancelable__StreamCancelable is SablierV2ProUnitTest, StreamExistent {
    /// @dev it should return false.
    function testIsCancelable__CancelableStream() external {
        uint256 daiStreamId = createDefaultDaiStream();
        bool actualCancelable = sablierV2Pro.isCancelable(daiStreamId);
        bool expectedCancelable = true;
        assertEq(actualCancelable, expectedCancelable);
    }
}

contract SablierV2Pro__IsCancelable__StreamNonCancelable is SablierV2ProUnitTest, StreamExistent {
    /// @dev it should return true.
    function testIsCancelable__NonCancelableStream() external {
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();
        bool actualCancelable = sablierV2Pro.isCancelable(nonCancelableDaiStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }
}
