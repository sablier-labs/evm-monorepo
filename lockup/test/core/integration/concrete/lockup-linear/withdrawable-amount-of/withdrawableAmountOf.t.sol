// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { WithdrawableAmountOf_Integration_Concrete_Test } from
    "./../../lockup/withdrawable-amount-of/withdrawableAmountOf.t.sol";
import { LockupLinear_Integration_Shared_Test, Integration_Test } from "./../LockupLinear.t.sol";

contract WithdrawableAmountOf_LockupLinear_Integration_Concrete_Test is
    LockupLinear_Integration_Shared_Test,
    WithdrawableAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Shared_Test, Integration_Test) {
        LockupLinear_Integration_Shared_Test.setUp();
    }

    function test_GivenCliffTimeInFuture() external givenSTREAMINGStatus {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() - 1 });
        uint128 actualWithdrawableAmount = lockupLinear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenNoPreviousWithdrawals() external givenSTREAMINGStatus givenCliffTimeNotInFuture {
        uint128 actualWithdrawableAmount = lockupLinear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenPreviousWithdrawal() external givenSTREAMINGStatus givenCliffTimeNotInFuture {
        lockupLinear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.WITHDRAW_AMOUNT() });

        uint128 actualWithdrawableAmount = lockupLinear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
