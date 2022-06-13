// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__IsCancelable__UnitTest is SablierV2ProUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool actualCancelable = sablierV2Pro.isCancelable(nonStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }

    /// @dev When the stream is cancelable, it should return false.
    function testIsCancelable__CancelableStream() external {
        uint256 streamId = createDefaultStream();
        bool actualCancelable = sablierV2Pro.isCancelable(streamId);
        bool expectedCancelable = true;
        assertEq(actualCancelable, expectedCancelable);
    }

    /// @dev When the stream is not cancelable, it should return true.
    function testIsCancelable__NonCancelableStream() external {
        bool cancelable = false;
        uint256 streamId = sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            cancelable
        );
        bool actualCancelable = sablierV2Pro.isCancelable(streamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }
}
