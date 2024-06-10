// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../../Integration.t.sol";

contract RefundableAmountOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.refundableAmountOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GivenBalanceZero() external view givenNotNull {
        // It should return zero.
        uint128 refundableAmount = flow.refundableAmountOf(defaultStreamId);
        assertEq(refundableAmount, 0, "refundable amount");
    }

    modifier givenBalanceNotZero() override {
        // Deposit into the stream.
        depositDefaultAmountToDefaultStream();
        _;
    }

    function test_GivenPaused() external givenNotNull givenBalanceNotZero {
        // Pause the stream.
        flow.pause(defaultStreamId);

        // It should return correct refundable amount.
        uint128 refundableAmount = flow.refundableAmountOf(defaultStreamId);
        assertEq(refundableAmount, ONE_MONTH_REFUNDABLE_AMOUNT, "refundable amount");
    }

    function test_WhenAmountOwedExceedsBalance() external givenNotNull givenBalanceNotZero givenNotPaused {
        // Simulate the passage of time until debt begins.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD });

        // It should return zero.
        uint128 refundableAmount = flow.refundableAmountOf(defaultStreamId);
        assertEq(refundableAmount, 0, "refundable amount");
    }

    function test_WhenAmountOwedDoesNotExceedBalance() external givenNotNull givenBalanceNotZero givenNotPaused {
        // It should return correct refundable amount.
        uint128 refundableAmount = flow.refundableAmountOf(defaultStreamId);
        assertEq(refundableAmount, ONE_MONTH_REFUNDABLE_AMOUNT, "refundable amount");
    }
}
