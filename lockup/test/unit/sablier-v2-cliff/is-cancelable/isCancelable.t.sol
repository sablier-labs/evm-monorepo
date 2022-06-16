// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__IsCancelable is SablierV2CliffUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool actualCancelable = sablierV2Cliff.isCancelable(nonStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }

    /// @dev When the stream is cancelable, it should return false.
    function testIsCancelable__CancelableStream() external {
        uint256 streamId = createDefaultStream();
        bool actualCancelable = sablierV2Cliff.isCancelable(streamId);
        bool expectedCancelable = true;
        assertEq(actualCancelable, expectedCancelable);
    }

    /// @dev When the stream is not cancelable, it should return true.
    function testIsCancelable__NonCancelableStream() external {
        bool cancelable = false;
        uint256 streamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            cancelable
        );
        bool actualCancelable = sablierV2Cliff.isCancelable(streamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }
}
