// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract WithdrawableAmountOf_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        openEnded.deposit(defaultStreamId, ONE_MONTH_STREAMED_AMOUNT);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertGiven_Null() external {
        expectRevertNull();
        openEnded.withdrawableAmountOf(nullStreamId);
    }

    function test_WithdrawableAmountOf_Canceled() external givenNotNull {
        openEnded.cancel(defaultStreamId);

        uint128 actualWithdrawableAmount = openEnded.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = openEnded.getRemainingAmount(defaultStreamId);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");
    }

    function test_WithdrawableAmountOf_RemainingAmountZero()
        external
        givenNotNull
        givenNotCanceled
        givenBalanceZero
        givenRemainingAmountZero
    {
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        assertEq(openEnded.getBalance(streamId), 0, "stream balance");
        assertEq(openEnded.getRemainingAmount(streamId), 0, "remaining amount");
        assertEq(openEnded.withdrawableAmountOf(streamId), 0, "withdrawable amount");
    }

    function test_WithdrawableAmountOf_RemainingAmountNotZero()
        external
        givenNotNull
        givenNotCanceled
        givenBalanceZero
        givenRemainingAmountNotZero
    {
        // Adjust the rate per second so that the remaining amount is greater than zero.
        openEnded.adjustRatePerSecond(defaultStreamId, RATE_PER_SECOND + 1);

        assertEq(openEnded.getBalance(defaultStreamId), 0, "stream balance");

        uint128 actualWithdrawableAmount = openEnded.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = openEnded.getRemainingAmount(defaultStreamId);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");
    }

    function test_WithdrawableAmountOf_BalanceLessThanOrEqualStreamedAmount()
        external
        givenNotNull
        givenNotCanceled
        givenBalanceNotZero
        givenRemainingAmountNotZero
    {
        // Adjust the rate per second so that the remaining amount is greater than zero.
        openEnded.adjustRatePerSecond(defaultStreamId, RATE_PER_SECOND + 1);

        uint128 depositAmount = 1e18;

        // Deposit more funds.
        openEnded.deposit(defaultStreamId, depositAmount);

        // Warp one more month into the future.
        vm.warp({ newTimestamp: block.timestamp + ONE_MONTH });

        uint128 actualWithdrawableAmount = openEnded.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = openEnded.getRemainingAmount(defaultStreamId) + depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");
    }

    function test_WithdrawableAmountOf()
        external
        givenNotNull
        givenNotCanceled
        givenBalanceNotZero
        givenRemainingAmountNotZero
    {
        uint128 newRatePerSecond = RATE_PER_SECOND + 1; // 0.001e18 + 1

        // Adjust the rate per second so that the remaining amount is greater than zero.
        openEnded.adjustRatePerSecond(defaultStreamId, newRatePerSecond);

        // Deposit more funds.
        defaultDeposit();

        // Warp one more month into the future.
        vm.warp({ newTimestamp: block.timestamp + ONE_MONTH });

        uint128 oneMonthStreamedAmount = ONE_MONTH * newRatePerSecond;

        uint128 actualWithdrawableAmount = openEnded.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = openEnded.getRemainingAmount(defaultStreamId) + oneMonthStreamedAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");
    }
}
