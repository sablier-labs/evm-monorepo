// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { WithdrawableAmountOf_Integration_Concrete_Test } from
    "../../lockup-base/withdrawable-amount-of/withdrawableAmountOf.t.sol";
import { Lockup_Linear_Integration_Concrete_Test, Integration_Test } from "./../LockupLinear.t.sol";

contract WithdrawableAmountOf_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Concrete_Test,
    WithdrawableAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Concrete_Test, Integration_Test) {
        Lockup_Linear_Integration_Concrete_Test.setUp();
    }

    function test_GivenCliffTimeInFuture() external givenSTREAMINGStatus {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() - 1 });
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenNoPreviousWithdrawals() external givenSTREAMINGStatus givenCliffTimeNotInFuture {
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaults.STREAMED_AMOUNT_26_PERCENT();
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenPreviousWithdrawal() external givenSTREAMINGStatus givenCliffTimeNotInFuture {
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.STREAMED_AMOUNT_26_PERCENT() });

        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
