// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract WithdrawableAmountOf_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertGiven_Null() external {
        expectRevertNull();
        flow.withdrawableAmountOf(nullStreamId);
    }

    function test_WithdrawableAmountOf_BalanceZero() external view givenNotNull givenBalanceZero {
        assertEq(flow.getBalance(defaultStreamId), 0, "stream balance");
        assertEq(flow.withdrawableAmountOf(defaultStreamId), 0, "withdrawable amount");
    }

    function test_WithdrawableAmountOf_BalanceLessThanRemainingAmount() external givenNotNull givenBalanceNotZero {
        // Simulate passage of time.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Deposit half of the streamed amount.
        uint128 depositAmount = ONE_MONTH_STREAMED_AMOUNT / 2;
        flow.deposit(defaultStreamId, depositAmount);

        // Adjust the rate per second so that the remaining amount is updated.
        flow.adjustRatePerSecond(defaultStreamId, RATE_PER_SECOND / 2);

        uint128 actualWithdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");
    }

    function test_WithdrawableAmountOf_StreamPaused() external givenNotNull givenBalanceNotZero givenPaused {
        // Deposit enough funds.
        depositToDefaultStream();

        // Simulate passage of time.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Pause the stream.
        flow.pause(defaultStreamId);

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        uint128 actualWithdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");
    }

    function test_WithdrawableAmountOf_SumLessThanBalance() external givenNotNull givenBalanceZero givenNotPaused {
        // Simulate passage of time.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // Deposit some funds.
        uint128 depositAmount = ONE_MONTH_STREAMED_AMOUNT + 100e18;
        flow.deposit(defaultStreamId, depositAmount);

        // Adjust the rate per second so that the remaining amount is updated.
        flow.adjustRatePerSecond(defaultStreamId, RATE_PER_SECOND * 2);

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        uint128 actualWithdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");

        // Simulate passage of time.
        vm.warp({ newTimestamp: WARP_ONE_MONTH + 2 weeks });

        actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        actualWithdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);
        expectedWithdrawableAmount = depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");
    }

    function test_WithdrawableAmountOf() external givenNotNull givenBalanceZero givenNotPaused {
        // Simulate passage of time.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        depositToDefaultStream();

        uint128 newRatePerSecond = RATE_PER_SECOND * 2;

        // Adjust the rate per second so that the remaining amount is updated.
        flow.adjustRatePerSecond(defaultStreamId, newRatePerSecond);

        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        uint128 expectedRemainingAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        uint128 actualWithdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");

        // Simulate passage of time.
        vm.warp({ newTimestamp: WARP_ONE_MONTH + 2 weeks });

        actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, expectedRemainingAmount, "remaining amount");

        // The withdrawable amount should be the calculated streamed amount since the adjustment moment (2 weeks in the
        // past to know) and the remaining amount which was updated to `ONE_MONTH_STREAMED_AMOUNT`.
        actualWithdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);
        expectedWithdrawableAmount = flow.streamedAmountOf(defaultStreamId) + ONE_MONTH_STREAMED_AMOUNT;

        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawable amount");
    }
}
