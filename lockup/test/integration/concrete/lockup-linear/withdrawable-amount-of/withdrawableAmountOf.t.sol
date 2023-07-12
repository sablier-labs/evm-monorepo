// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupLinear_Integration_Concrete_Test } from "../LockupLinear.t.sol";
import { WithdrawableAmountOf_Integration_Concrete_Test } from
    "../../lockup/withdrawable-amount-of/withdrawableAmountOf.t.sol";

contract WithdrawableAmountOf_LockupLinear_Integration_Concrete_Test is
    LockupLinear_Integration_Concrete_Test,
    WithdrawableAmountOf_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Concrete_Test, WithdrawableAmountOf_Integration_Concrete_Test)
    {
        LockupLinear_Integration_Concrete_Test.setUp();
        WithdrawableAmountOf_Integration_Concrete_Test.setUp();
    }

    function test_WithdrawableAmountOf_CliffTimeInTheFuture()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        uint128 actualWithdrawableAmount = lockupLinear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenCliffTimeNotInTheFuture() {
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    function test_WithdrawableAmountOf_NoPreviousWithdrawals()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
        whenCliffTimeNotInTheFuture
    {
        uint128 actualWithdrawableAmount = lockupLinear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenPreviousWithdrawals() {
        lockupLinear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.WITHDRAW_AMOUNT() });
        _;
    }

    function test_WithdrawableAmountOf_WithWithdrawals()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
        whenCliffTimeNotInTheFuture
        whenPreviousWithdrawals
    {
        uint128 actualWithdrawableAmount = lockupLinear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
