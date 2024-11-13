// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { WithdrawableAmountOf_Integration_Concrete_Test } from
    "./../../lockup-base/withdrawable-amount-of/withdrawableAmountOf.t.sol";
import { Lockup_Dynamic_Integration_Concrete_Test, Integration_Test } from "../LockupDynamic.t.sol";

contract WithdrawableAmountOf_Lockup_Dynamic_Integration_Concrete_Test is
    Lockup_Dynamic_Integration_Concrete_Test,
    WithdrawableAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Dynamic_Integration_Concrete_Test, Integration_Test) {
        Lockup_Dynamic_Integration_Concrete_Test.setUp();
    }

    function test_GivenStartTimeInPresent() external givenSTREAMINGStatus {
        vm.warp({ newTimestamp: defaults.START_TIME() });
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenNoPreviousWithdrawals() external givenSTREAMINGStatus givenStartTimeInPast {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + defaults.CLIFF_DURATION() + 3750 seconds });

        // Run the test.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        // The second term is 7,500*0.5^{0.5}
        uint128 expectedWithdrawableAmount = defaults.segments()[0].amount + 5303.30085889910643e18;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenPreviousWithdrawal() external givenSTREAMINGStatus givenStartTimeInPast {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + defaults.CLIFF_DURATION() + 3750 seconds });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.WITHDRAW_AMOUNT() });

        // Run the test.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // The second term is 7,500*0.5^{0.5}
        uint128 expectedWithdrawableAmount =
            defaults.segments()[0].amount + 5303.30085889910643e18 - defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
