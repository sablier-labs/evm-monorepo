// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../../Integration.t.sol";

contract WithdrawableAmountOf_Integration_Concrete_Test is Integration_Test {
    function test_WithdrawableAmountOf() external givenNotNull givenBalanceNotZero {
        // Deposit into stream.
        depositToDefaultStream();

        // Simulate one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        // It should return the correct withdrawable amount.
        uint128 withdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);
        assertEq(withdrawableAmount, ONE_MONTH_DEBT_6D, "withdrawable amount");
    }
}
