// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract RefundableAmountOf_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertGiven_Null() external {
        _test_RevertGiven_Null();
        openEnded.refundableAmountOf(nullStreamId);
    }

    function test_RevertGiven_Canceled() external givenNotNull {
        _test_RevertGiven_Canceled();
        openEnded.refundableAmountOf(defaultStreamId);
    }

    function test_RefundableAmountOf_BalanceZero() external givenNotNull givenNotCanceled {
        uint128 refundableAmount = openEnded.refundableAmountOf(defaultStreamId);
        assertEq(refundableAmount, 0, "refundable amount");
    }

    function test_RefundableAmountOf_BalanceLessThanOrEqualStreamedAmount() external givenNotNull givenNotCanceled {
        uint128 depositAmount = 1e18;
        openEnded.deposit(defaultStreamId, depositAmount);

        vm.warp({ timestamp: WARP_ONE_MONTH });
        uint128 refundableAmount = openEnded.refundableAmountOf(defaultStreamId);
        assertEq(refundableAmount, 0, "refundable amount");
    }

    function test_RefundableAmountOf() external givenNotNull givenNotCanceled {
        defaultDeposit();

        vm.warp({ timestamp: WARP_ONE_MONTH });
        uint128 refundableAmount = openEnded.refundableAmountOf(defaultStreamId);
        assertEq(refundableAmount, ONE_MONTH_REFUNDABLE_AMOUNT, "refundable amount");
    }
}
