// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Linear_Integration_Basic_Test } from "../Linear.t.sol";
import { WithdrawableAmountOf_Integration_Basic_Test } from
    "../../lockup/withdrawable-amount-of/withdrawableAmountOf.t.sol";

contract WithdrawableAmountOf_Linear_Integration_Basic_Test is
    Linear_Integration_Basic_Test,
    WithdrawableAmountOf_Integration_Basic_Test
{
    function setUp()
        public
        virtual
        override(Linear_Integration_Basic_Test, WithdrawableAmountOf_Integration_Basic_Test)
    {
        Linear_Integration_Basic_Test.setUp();
        WithdrawableAmountOf_Integration_Basic_Test.setUp();
    }

    function test_WithdrawableAmountOf_CliffTimeInTheFuture()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
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
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenPreviousWithdrawals() {
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.WITHDRAW_AMOUNT() });
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
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
