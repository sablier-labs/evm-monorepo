// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2UnitTest } from "../../SablierV2UnitTest.t.sol";

contract SablierV2Linear__Cancel__UnitTest is SablierV2UnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultLinearStream();
    }

    /// @dev When the linear stream does not exist, it should revert.
    function testCannotCancel__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Linear.cancel(nonStreamId);
    }

    /// @dev When the linear stream does not exist, it should revert.
    function testCannotCancel__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When caller is the recipient, it should make the withdrawal.
    function testCancel__CallerRecipient() external {
        // Make the recipient the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.recipient);

        // Run the test.
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When the linear stream is non-cancelable, it should revert.
    function testCannotCancel__StreamNonCancelable() external {
        // Creaate the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            linearStream.startTime,
            linearStream.stopTime,
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
        // Warp to the end of the linear stream.
        vm.warp(linearStream.stopTime);

        // Run the test.
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When the stream ended, it should delete the linear stream.
    function testCancel__StreamEnded__DeleteLinearStream() external {
        // Warp to the end of the linear stream.
        vm.warp(linearStream.stopTime);

        // Run the test.
        sablierV2Linear.cancel(streamId);
        ISablierV2Linear.LinearStream memory expectedLinearStream;
        ISablierV2Linear.LinearStream memory deletedLinearStream = sablierV2Linear.getLinearStream(streamId);
        assertEq(expectedLinearStream, deletedLinearStream);
    }

    /// @dev When the stream ended, it should emit a Cancel event.
    function testCancel__StreamEnded__Event() public {
        // Warp to the end of the linear stream.
        vm.warp(linearStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = linearStream.depositAmount;
        uint256 returnAmount = 0;
        emit Cancel(streamId, linearStream.recipient, withdrawAmount, returnAmount);
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should cancel the stream.
    function testCancel__StreamOngoing() external {
        // Warp to 36 seconds after the start time (1% of the default linear stream duration).
        vm.warp(linearStream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        sablierV2Linear.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should delete the linear stream.
    function testCancel__StreamOngoing__DeleteLinearStream() external {
        // Warp to the end of the linear stream.
        vm.warp(linearStream.stopTime);

        // Run the test.
        sablierV2Linear.cancel(streamId);
        ISablierV2Linear.LinearStream memory expectedLinearStream;
        ISablierV2Linear.LinearStream memory deletedLinearStream = sablierV2Linear.getLinearStream(streamId);
        assertEq(expectedLinearStream, deletedLinearStream);
    }

    /// @dev When the stream is ongoing, it should emit a Cancel event.
    function testCancel__StreamOngoing__Event() public {
        // Warp to the end of the linear stream.
        vm.warp(linearStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = linearStream.depositAmount;
        uint256 returnAmount = 0;
        emit Cancel(streamId, linearStream.recipient, withdrawAmount, returnAmount);
        sablierV2Linear.cancel(streamId);
    }
}
