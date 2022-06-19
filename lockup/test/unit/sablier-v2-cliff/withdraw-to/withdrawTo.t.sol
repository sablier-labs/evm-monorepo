// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__WithdrawTo is SablierV2CliffUnitTest {
    uint256 internal streamId;
    address internal toAlice;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);

        // Make Alice the address that will receive the tokens.
        toAlice = users.alice;
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotWithdrawTo__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdrawTo(nonStreamId, toAlice, withdrawAmount);
    }

    /// @dev When the to address is zero, it should revert.
    function testCannotWithdrawTo__ToZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawZeroAddress.selector));
        address toZero = address(0);
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdrawTo(streamId, toZero, withdrawAmount);
    }

    /// @dev When the caller is the sender, it should revert.
    function testCannotWithdrawTo__CallerUnauthorized__Sender() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.sender));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdrawTo(streamId, toAlice, withdrawAmount);
    }

    /// @dev When the caller is an unauthorized third-party, it should revert.
    function testCannotWithdrawTo__CallerUnauthorized__Eve() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdrawTo(streamId, toAlice, withdrawAmount);
    }

    /// @dev When the withdraw amount is zero, it should revert.
    function testCannotWithdrawTo__WithdrawAmountZero() external {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, streamId));
        uint256 withdrawAmount = 0;
        sablierV2Cliff.withdrawTo(streamId, toAlice, withdrawAmount);
    }

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdrawTo__WithdrawAmountGreaterThanWithdrawableAmount() external {
        uint256 withdrawAmountMaxUint256 = MAX_UINT_256;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                streamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Cliff.withdrawTo(streamId, toAlice, withdrawAmountMaxUint256);
    }

    /// @dev When the to address is the recipient, it should make the withdrawal.
    function testWithdrawTo__Recipient() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.withdrawTo(streamId, toAlice, WITHDRAW_AMOUNT);
    }

    /// @dev When the stream ended, it should make the withdrawal and delete the stream.
    function testWithdrawTo__ThirdParty__StreamEnded() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        sablierV2Cliff.withdrawTo(streamId, toAlice, withdrawAmount);
        ISablierV2Cliff.Stream memory deletedStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev When the stream ended, it should emit a Withdraw event.
    function testWithdrawTo__ThirdParty__StreamEnded__Event() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = stream.depositAmount;
        emit Withdraw(streamId, toAlice, withdrawAmount);
        sablierV2Cliff.withdrawTo(streamId, toAlice, withdrawAmount);
    }

    /// @dev When the stream is ongoing, it should make the withdrawal and update the withdrawn amount.
    function testWithdrawTo__ThirdParty__StreamOngoing() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.withdrawTo(streamId, toAlice, WITHDRAW_AMOUNT);
        ISablierV2Cliff.Stream memory actualStream = sablierV2Cliff.getStream(streamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev When the stream is ongoing, it should emit a Withdraw event.
    function testWithdrawTo__ThirdParty__StreamOngoing__Event() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(streamId, toAlice, withdrawAmount);
        sablierV2Cliff.withdrawTo(streamId, toAlice, withdrawAmount);
    }
}
