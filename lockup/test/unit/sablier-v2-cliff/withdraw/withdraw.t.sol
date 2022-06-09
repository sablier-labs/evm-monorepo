// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__Withdraw__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotWithdraw__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdraw(nonStreamId, withdrawAmount);
    }

    /// @dev When the caller is neither the sender nor the recipient, it should revert.
    function testCannotWithdraw__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }

    /// @dev When the caller is the sender, it should make the withdrawal.
    function testWithdraw__CallerSender() external {
        // Make the sender the `msg.sender` in this test case.
        changePrank(users.sender);

        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);
        uint256 withdrawAmount = WITHDRAW_AMOUNT;

        // Run the test.
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }

    /// @dev When the withdraw amount is zero, it should revert.
    function testCannotWithdraw__WithdrawAmountZero() public {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, streamId));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdraw__WithdrawAmountGreaterThanWithdrawableAmount() public {
        uint256 withdrawAmountMaxUint256 = type(uint256).max;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                streamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Cliff.withdraw(streamId, withdrawAmountMaxUint256);
    }

    /// @dev When the stream ended, it should withdraw everything.
    function testWithdraw__StreamEnded() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }

    /// @dev When the stream ended, it should delete the stream.
    function testWithdraw__StreamEnded__DeleteStream() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
        ISablierV2Cliff.Stream memory deletedStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev When the stream ended, it should emit a Withdraw event.
    function testWithdraw__StreamEnded__Event() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = stream.depositAmount;
        emit Withdraw(streamId, stream.recipient, withdrawAmount);
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }

    /// @dev When the stream is ongoing, it should make the withdrawal.
    function testWithdraw__StreamOngoing() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.withdraw(streamId, WITHDRAW_AMOUNT);
    }

    /// @dev When the stream is ongoing, it should update the withdrawn amount.
    function testWithdraw__StreamOngoing__UpdateWithdrawnAmount() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawnAmount = WITHDRAW_AMOUNT;
        sablierV2Cliff.withdraw(streamId, withdrawnAmount);
        ISablierV2Cliff.Stream memory queriedStream = sablierV2Cliff.getStream(streamId);
        uint256 actualWithdrawnAmount = queriedStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = stream.withdrawnAmount + withdrawnAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev When the stream is ongoing, it should emit a Withdraw event.
    function testWithdraw__StreamOngoing__Event() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        emit Withdraw(streamId, stream.recipient, withdrawAmount);
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }
}
