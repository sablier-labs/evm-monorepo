// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__Cancel__UnitTest is SablierV2ProUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotCancel__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Pro.cancel(nonStreamId);
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotCancel__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Pro.cancel(streamId);
    }

    /// @dev When caller is the recipient, it should make the withdrawal.
    function testCancel__CallerRecipient() external {
        // Make the recipient the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.recipient);

        // Run the test.
        sablierV2Pro.cancel(streamId);
    }

    /// @dev When the stream is non-cancelable, it should revert.
    function testCannotCancel__StreamNonCancelable() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            cancelable
        );

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableStreamId)
        );
        sablierV2Pro.cancel(nonCancelableStreamId);
    }

    /// @dev When the stream ended, it should cancel the stream.
    function testCancel__StreamEnded() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Pro.cancel(streamId);
    }

    /// @dev When the stream ended, it should delete the stream.
    function testCancel__StreamEnded__DeleteStream() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Pro.cancel(streamId);
        ISablierV2Pro.Stream memory expectedStream;
        ISablierV2Pro.Stream memory deletedStream = sablierV2Pro.getStream(streamId);
        assertEq(expectedStream, deletedStream);
    }

    /// @dev When the stream ended, it should emit a Cancel event.
    function testCancel__StreamEnded__Event() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        uint256 returnAmount = 0;
        vm.expectEmit(true, true, false, true);
        emit Cancel(streamId, stream.recipient, withdrawAmount, returnAmount);
        sablierV2Pro.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should cancel the stream.
    function testCancel__StreamOngoing() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        sablierV2Pro.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should delete the stream.
    function testCancel__StreamOngoing__DeleteStream() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Pro.cancel(streamId);
        ISablierV2Pro.Stream memory expectedStream;
        ISablierV2Pro.Stream memory deletedStream = sablierV2Pro.getStream(streamId);
        assertEq(expectedStream, deletedStream);
    }

    /// @dev When the stream is ongoing, it should emit a Cancel event.
    function testCancel__StreamOngoing__Event() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        uint256 returnAmount = 0;
        vm.expectEmit(true, true, false, true);
        emit Cancel(streamId, stream.recipient, withdrawAmount, returnAmount);
        sablierV2Pro.cancel(streamId);
    }
}
