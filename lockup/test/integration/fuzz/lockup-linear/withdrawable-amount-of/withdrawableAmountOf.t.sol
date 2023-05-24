// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Broker, LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Integration_Fuzz_Test } from "../Linear.t.sol";
import { WithdrawableAmountOf_Integration_Shared_Test } from
    "../../../shared/lockup/withdrawable-amount-of/withdrawableAmountOf.t.sol";

contract WithdrawableAmountOf_Linear_Integration_Fuzz_Test is
    Linear_Integration_Fuzz_Test,
    WithdrawableAmountOf_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(Linear_Integration_Fuzz_Test, WithdrawableAmountOf_Integration_Shared_Test)
    {
        Linear_Integration_Fuzz_Test.setUp();
        WithdrawableAmountOf_Integration_Shared_Test.setUp();
    }

    function testFuzz_WithdrawableAmountOf_CliffTimeInTheFuture(uint40 timeJump)
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
    {
        timeJump = boundUint40(timeJump, 0, defaults.CLIFF_DURATION() - 1);
        vm.warp({ timestamp: defaults.START_TIME() + timeJump });
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenCliffTimeNotInTheFuture() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: ZERO });
        changePrank({ msgSender: users.sender });
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
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
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenCliffTimeNotInTheFuture
    {
        vm.assume(depositAmount != 0);
        timeJump = boundUint40(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Mint enough assets to the sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream. The broker fee is disabled so that it doesn't interfere with the calculations.
        LockupLinear.CreateWithRange memory params = defaults.createWithRange();
        params.broker = Broker({ account: address(0), fee: ZERO });
        params.totalAmount = depositAmount;
        uint256 streamId = linear.createWithRange(params);

        // Simulate the passage of time.
        uint40 currentTime = defaults.START_TIME() + timeJump;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmount(currentTime, depositAmount);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenPreviousWithdrawals() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
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
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenCliffTimeNotInTheFuture
        whenPreviousWithdrawals
    {
        timeJump = boundUint40(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);
        depositAmount = boundUint128(depositAmount, 10_000, MAX_UINT128);

        // Define the current time.
        uint40 currentTime = defaults.START_TIME() + timeJump;

        // Bound the withdraw amount.
        uint128 streamedAmount = calculateStreamedAmount(currentTime, depositAmount);
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Mint enough assets to the sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream. The broker fee is disabled so that it doesn't interfere with the calculations.
        LockupLinear.CreateWithRange memory params = defaults.createWithRange();
        params.broker = Broker({ account: address(0), fee: ZERO });
        params.totalAmount = depositAmount;
        uint256 streamId = linear.createWithRange(params);

        // Simulate the passage of time.
        vm.warp({ timestamp: currentTime });

        // Make the withdrawal.
        linear.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
