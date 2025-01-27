// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Lockup_Linear_Integration_Fuzz_Test } from "./LockupLinear.t.sol";

contract WithdrawableAmountOf_Lockup_Linear_Integration_Fuzz_Test is Lockup_Linear_Integration_Fuzz_Test {
    function testFuzz_WithdrawableAmountOf_CliffTimeInFuture(uint40 timeJump)
        external
        givenNotNull
        givenNotCanceledStream
    {
        timeJump = boundUint40(timeJump, 0, defaults.CLIFF_DURATION() - 1);
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Status streaming
    /// - Status settled
    function testFuzz_WithdrawableAmountOf_NoPreviousWithdrawals(
        uint40 timeJump,
        uint128 depositAmount
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenCliffTimeNotInFuture
    {
        vm.assume(depositAmount != 0);
        timeJump = boundUint40(timeJump, defaults.WARP_26_PERCENT_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Mint enough tokens to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream. The broker fee is disabled so that it doesn't interfere with the calculations.
        _defaultParams.createWithTimestamps.broker = defaults.brokerNull();
        _defaultParams.unlockAmounts = defaults.unlockAmountsZero();
        _defaultParams.createWithTimestamps.totalAmount = depositAmount;
        uint256 streamId = createDefaultStream();

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Run the test.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = calculateLockupLinearStreamedAmount(
            defaults.START_TIME(),
            defaults.CLIFF_TIME(),
            defaults.END_TIME(),
            depositAmount,
            _defaultParams.unlockAmounts
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple deposit amounts
    /// - Multiple withdraw amounts
    /// - Status streaming
    /// - Status settled
    /// - Status depleted
    /// - Withdraw amount equal to deposited amount and not
    function testFuzz_WithdrawableAmountOf(
        uint40 timeJump,
        uint128 depositAmount,
        uint128 withdrawAmount
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenCliffTimeNotInFuture
        givenPreviousWithdrawal
    {
        depositAmount = boundUint128(depositAmount, 10_000, MAX_UINT128);

        // Mint enough tokens to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream. The broker fee is disabled so that it doesn't interfere with the calculations.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestampsBrokerNull();
        params.totalAmount = depositAmount;
        LockupLinear.UnlockAmounts memory unlockAmounts = defaults.unlockAmountsZero();
        uint256 streamId = lockup.createWithTimestampsLL(params, unlockAmounts, defaults.CLIFF_TIME());

        timeJump = boundUint40(timeJump, defaults.WARP_26_PERCENT_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Bound the withdraw amount.
        uint128 streamedAmount = calculateLockupLinearStreamedAmount(
            defaults.START_TIME(), defaults.CLIFF_TIME(), defaults.END_TIME(), depositAmount, unlockAmounts
        );
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
