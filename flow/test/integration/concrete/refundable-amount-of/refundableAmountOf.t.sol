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
        uint128 actualRefundableAmount = flow.refundableAmountOf(defaultStreamId);
        assertEq(actualRefundableAmount, 0, "refundable amount");
    }

    function test_GivenPaused() external givenNotNull givenBalanceNotZero {
        // Pause the stream.
        flow.pause(defaultStreamId);

        // It should return the correct refundable amount.
        uint128 actualRefundableAmount = flow.refundableAmountOf(defaultStreamId);
        assertEq(actualRefundableAmount, ONE_MONTH_REFUNDABLE_AMOUNT_6D, "refundable amount");
    }

    function test_WhenTotalDebtExceedsBalance() external givenNotNull givenBalanceNotZero givenNotPaused {
        // Simulate the passage of time until debt becomes uncovered.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD });

        // It should return zero.
        uint128 actualRefundableAmount = flow.refundableAmountOf(defaultStreamId);
        assertEq(actualRefundableAmount, 0, "refundable amount");
    }

    function test_WhenTotalDebtNotExceedBalance() external givenNotNull givenBalanceNotZero givenNotPaused {
        // It should return the correct refundable amount.
        uint128 actualRefundableAmount = flow.refundableAmountOf(defaultStreamId);
        assertEq(actualRefundableAmount, ONE_MONTH_REFUNDABLE_AMOUNT_6D, "refundable amount");
    }
}
