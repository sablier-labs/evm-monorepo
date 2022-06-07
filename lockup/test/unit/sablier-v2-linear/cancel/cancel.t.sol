// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Cancel__UnitTest is SablierV2LinearUnitTest {
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
        sablierV2Linear.cancel(nonStreamId);
    }

    /// @dev When the caller is not authorized, it should revert.
    function testCannotCancel__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When caller is the recipient, it should make the withdrawal.
    function testCancel__CallerRecipient() external {
        // Make the recipient the `msg.sender` in this test case.
        changePrank(users.recipient);

        // Run the test.
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When the stream is non-cancelable, it should revert.
    function testCannotCancel__StreamNonCancelable() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.stopTime,
            cancelable
        );

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableStreamId)
        );
        sablierV2Linear.cancel(nonCancelableStreamId);
    }

    /// @dev When the stream ended, it should cancel the stream.
    function testCancel__StreamEnded() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When the stream ended, it should delete the stream.
    function testCancel__StreamEnded__DeleteStream() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Linear.cancel(streamId);
        ISablierV2Linear.Stream memory expectedStream;
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(streamId);
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
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should cancel the stream.
    function testCancel__StreamOngoing() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should delete the stream.
    function testCancel__StreamOngoing__DeleteStream() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Linear.cancel(streamId);
        ISablierV2Linear.Stream memory expectedStream;
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(streamId);
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
        sablierV2Linear.cancel(streamId);
    }
}
