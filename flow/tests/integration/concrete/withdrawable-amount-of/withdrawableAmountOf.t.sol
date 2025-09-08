// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract WithdrawableAmountOf_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function test_WithdrawableAmountOf() external givenNotNull givenBalanceNotZero {
        // Deposit into stream.
        depositToDefaultStream();

        // Simulate one month of streaming.
        vm.warp({ newTimestamp: ONE_MONTH_SINCE_CREATE });

        // It should return the correct withdrawable amount.
        uint128 withdrawableAmount = flow.withdrawableAmountOf(defaultStreamId);
        assertEq(withdrawableAmount, ONE_MONTH_DEBT_6D, "withdrawable amount");
    }
}
