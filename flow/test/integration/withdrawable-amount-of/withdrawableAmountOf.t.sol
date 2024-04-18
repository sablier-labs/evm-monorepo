// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract WithdrawableAmountOf_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertGiven_Null() external {
        _test_RevertGiven_Null();
        openEnded.withdrawableAmountOf(nullStreamId);
    }

    function test_RevertGiven_Canceled() external givenNotNull {
        _test_RevertGiven_Canceled();
        openEnded.withdrawableAmountOf(defaultStreamId);
    }

    function test_WithdrawableAmountOf_BalanceZero() external view givenNotNull givenNotCanceled {
        uint128 withdrawableAmount = openEnded.withdrawableAmountOf(defaultStreamId);
        assertEq(withdrawableAmount, 0, "withdrawable amount");
    }

    function test_WithdrawableAmountOf_BalanceLessThanOrEqualStreamedAmount() external givenNotNull givenNotCanceled {
        uint128 depositAmount = 1e18;
        openEnded.deposit(defaultStreamId, depositAmount);

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
        uint128 withdrawableAmount = openEnded.withdrawableAmountOf(defaultStreamId);
        assertEq(withdrawableAmount, depositAmount, "withdrawable amount");
    }

    function test_WithdrawableAmountOf() external givenNotNull givenNotCanceled {
        defaultDeposit();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
        uint128 withdrawableAmount = openEnded.withdrawableAmountOf(defaultStreamId);
        assertEq(withdrawableAmount, ONE_MONTH_STREAMED_AMOUNT, "withdrawable amount");
    }
}
