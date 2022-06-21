// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__Cancel is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultDaiStream();
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotCancel__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Cliff.cancel(nonStreamId);
    }

    /// @dev When the caller is neither the sender nor the recipient, it should revert.
    function testCannotCancel__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When caller is the recipient, it should cancel and delete the stream.
    function testCancel__CallerRecipient() external {
        // Make the recipient the `msg.sender` in this test case.
        changePrank(users.recipient);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
        ISablierV2Cliff.Stream memory deletedStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev When the stream is non-cancelable, it should revert.
    function testCannotCancel__StreamNonCancelable() external {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableDaiStreamId)
        );
        sablierV2Cliff.cancel(nonCancelableDaiStreamId);
    }

    /// @dev When the stream ended, it should cancel and delete the stream.
    function testCancel__StreamEnded() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
        ISablierV2Cliff.Stream memory deletedStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev When the stream ended, it should emit a Cancel event.
    function testCancel__StreamEnded__Event() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = daiStream.depositAmount;
        uint256 returnAmount = 0;
        emit Cancel(streamId, daiStream.recipient, withdrawAmount, returnAmount);
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should cancel and delete the stream.
    function testCancel__StreamOngoing() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
        ISablierV2Cliff.Stream memory deletedStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev When the stream is ongoing, it should emit a Cancel event.
    function testCancel__StreamOngoing__Event() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        uint256 returnAmount = daiStream.depositAmount - WITHDRAW_AMOUNT;
        vm.expectEmit(true, true, false, true);
        emit Cancel(streamId, daiStream.recipient, withdrawAmount, returnAmount);
        sablierV2Cliff.cancel(streamId);
    }
}
