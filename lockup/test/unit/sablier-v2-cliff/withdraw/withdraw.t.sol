// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__Withdraw__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultCliffStream();

        // Make the recipient the `msg.sender` in this test suite.
        vm.stopPrank();
        vm.startPrank(users.recipient);
    }

    /// @dev When the cliff stream does not exist, it should revert.
    function testCannotWithdraw__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdraw(nonStreamId, withdrawAmount);
    }

    /// @dev When the cliff stream does not exist, it should revert.
    function testCannotWithdraw__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }

    /// @dev When the caller is the sender, it should make the withdrawal.
    function testWithdraw__CallerSender() external {
        // Make the sender the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.sender);

        // Warp to 36 seconds after the start time (1% of the default cliff stream duration).
        vm.warp(cliffStream.startTime + DEFAULT_TIME_OFFSET);
        uint256 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;

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
        // Warp to the end of the cliff stream.
        vm.warp(cliffStream.stopTime);

        // Run the test.
        uint256 withdrawAmount = cliffStream.depositAmount;
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }

    /// @dev When the stream ended, it should delete the cliff stream.
    function testWithdraw__StreamEnded__DeleteCliffStream() public {
        // Warp to the end of the cliff stream.
        vm.warp(cliffStream.stopTime);

        // Run the test.
        uint256 withdrawAmount = cliffStream.depositAmount;
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
        ISablierV2Cliff.CliffStream memory expectedCliffStream;
        ISablierV2Cliff.CliffStream memory deletedCliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(expectedCliffStream, deletedCliffStream);
    }

    /// @dev When the stream ended, it should emit a Withdraw event.
    function testWithdraw__StreamEnded__Event() public {
        // Warp to the end of the cliff stream.
        vm.warp(cliffStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = cliffStream.depositAmount;
        emit Withdraw(streamId, cliffStream.recipient, withdrawAmount);
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }

    /// @dev When the stream is ongoing, it should make the withdrawal.
    function testWithdraw__StreamOngoing() public {
        // Warp to 36 seconds after the start time (1% of the default cliff stream duration).
        vm.warp(cliffStream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.withdraw(streamId, DEFAULT_WITHDRAW_AMOUNT);
    }

    /// @dev When the stream is ongoing, it should update the withdrawn amount.
    function testWithdraw__StreamOngoing__UpdateWithdrawnAmount() public {
        // Warp to 36 seconds after the start time (1% of the default cliff stream duration).
        vm.warp(cliffStream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        uint256 withdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        uint256 expectedWithdrawnAmount = cliffStream.withdrawnAmount + withdrawnAmount;
        sablierV2Cliff.withdraw(streamId, withdrawnAmount);
        ISablierV2Cliff.CliffStream memory cliffStream = sablierV2Cliff.getCliffStream(streamId);
        uint256 actualWithdrawnAmount = cliffStream.withdrawnAmount;
        assertEq(expectedWithdrawnAmount, actualWithdrawnAmount);
    }

    /// @dev When the stream is ongoing, it should emit a Withdraw event.
    function testWithdraw__StreamOngoing__Event() public {
        // Warp to 36 seconds after the start time (1% of the default cliff stream duration).
        vm.warp(cliffStream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        emit Withdraw(streamId, cliffStream.recipient, withdrawAmount);
        sablierV2Cliff.withdraw(streamId, withdrawAmount);
    }
}
