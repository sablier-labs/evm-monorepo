// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract Withdraw_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenStreamActive() {
        _;
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    modifier whenWithdrawAmountNotZero() {
        _;
    }

    modifier whenWithdrawAmountNotGreaterThanWithdrawableAmount() {
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testFuzz_Withdraw_CallerRecipient(address to)
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountNotGreaterThanWithdrawableAmount
    {
        vm.assume(to != address(0));

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testFuzz_Withdraw_CallerApprovedOperator(address to)
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountNotGreaterThanWithdrawableAmount
    {
        vm.assume(to != address(0));

        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenCallerSender() {
        // Make the sender the caller in this test suite.
        changePrank({ msgSender: users.sender });
        _;
    }

    modifier whenCurrentTimeLessThanEndTime() {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testFuzz_Withdraw_RecipientNotContract(
        uint256 timeWarp,
        address to,
        uint128 withdrawAmount
    )
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountNotGreaterThanWithdrawableAmount
        whenCallerSender
        whenCurrentTimeLessThanEndTime
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(to != address(0) && to.code.length == 0);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream with the fuzzed recipient that is not a contract.
        uint256 streamId = createDefaultStreamWithRecipient(to);

        // Bound the withdraw amount.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the ERC-20 assets to be transferred to the recipient.
        expectTransferCall({ to: to, amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: streamId, to: to, amount: withdrawAmount });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: to, amount: withdrawAmount });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenRecipientContract() {
        _;
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    /// @dev it should make the withdrawal, update the withdrawn amount, and emit a {WithdrawFromLockupStream} event.
    function testFuzz_Withdraw(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountNotGreaterThanWithdrawableAmount
        whenCallerSender
        whenCurrentTimeLessThanEndTime
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Create the stream with a contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Bound the withdraw amount.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the ERC-20 assets to be transferred to the recipient.
        expectTransferCall({ to: address(goodRecipient), amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus =
            withdrawAmount == DEFAULT_DEPOSIT_AMOUNT ? Lockup.Status.DEPLETED : Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
