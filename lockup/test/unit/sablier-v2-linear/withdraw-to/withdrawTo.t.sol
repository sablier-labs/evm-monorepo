// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__WithdrawTo__UnitTest is SablierV2LinearUnitTest {
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
    function testCannotWithdrawTo__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        address to = users.alice;
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(nonStreamId, to, withdrawAmount);
    }

    /// @dev When the to address is zero, it should revert.
    function testCannotWithdrawTo__ZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawZeroAddress.selector));
        address to = address(0);
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the caller is the sender, it should revert.
    function testCannotWithdrawTo__CallerSender() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.sender));
        address to = users.alice;
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the caller is an unauthorized third-party, it should revert.
    function testCannotWithdrawTo__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        address to = users.alice;
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the withdraw amount is zero, it should revert.
    function testCannotWithdrawTo__WithdrawAmountZero() public {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, streamId));
        address to = users.alice;
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdrawTo__WithdrawAmountGreaterThanWithdrawableAmount() public {
        uint256 withdrawAmount = type(uint256).max;
        uint256 withdrawableAmount = 0;
        address to = users.alice;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                streamId,
                withdrawAmount,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the to address is the recipient, it should make the withdrawal.
    function testWithdrawTo__Recipient() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        address to = stream.recipient;
        sablierV2Linear.withdrawTo(streamId, to, WITHDRAW_AMOUNT);
    }

    /// @dev When the stream ended, it should withdraw everything.
    function testWithdrawTo__ThirdParty__StreamEnded() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        address to = users.alice;
        uint256 withdrawAmount = stream.depositAmount;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the stream ended, it should delete the stream.
    function testWithdrawTo__ThirdParty__StreamEnded__DeleteStream() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        address to = users.alice;
        uint256 withdrawAmount = stream.depositAmount;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
        ISablierV2Linear.Stream memory expectedStream;
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(streamId);
        assertEq(expectedStream, deletedStream);
    }

    /// @dev When the stream ended, it should emit a Withdraw event.
    function testWithdrawTo__ThirdParty__StreamEnded__Event() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        address to = users.alice;
        uint256 withdrawAmount = stream.depositAmount;
        emit Withdraw(streamId, to, withdrawAmount);
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the stream is ongoing, it should make the withdrawal.
    function testWithdrawTo__ThirdParty__StreamOngoing() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        address to = users.alice;
        sablierV2Linear.withdrawTo(streamId, to, WITHDRAW_AMOUNT);
    }

    /// @dev When the stream is ongoing, it should update the withdrawn amount.
    function testWithdrawTo__ThirdParty__StreamOngoing__UpdateWithdrawnAmount() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        address to = users.alice;
        uint256 withdrawnAmount = WITHDRAW_AMOUNT;
        uint256 expectedWithdrawnAmount = stream.withdrawnAmount + withdrawnAmount;
        sablierV2Linear.withdrawTo(streamId, to, withdrawnAmount);
        ISablierV2Linear.Stream memory stream = sablierV2Linear.getStream(streamId);
        uint256 actualWithdrawnAmount = stream.withdrawnAmount;
        assertEq(expectedWithdrawnAmount, actualWithdrawnAmount);
    }

    /// @dev When the stream is ongoing, it should emit a Withdraw event.
    function testWithdrawTo__ThirdParty__StreamOngoing__Event() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        address to = users.alice;
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(streamId, to, withdrawAmount);
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }
}
