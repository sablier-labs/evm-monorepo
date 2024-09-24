// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../../Integration.t.sol";

contract CoveredDebtOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.coveredDebtOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GivenBalanceZero() external givenNotNull {
        // Create a new stream with zero balance.
        uint256 streamId = createDefaultStream(dai);

        // It should return zero.
        uint128 coveredDebt = flow.coveredDebtOf(streamId);
        assertEq(coveredDebt, 0, "covered debt");
    }

    function test_WhenTotalDebtExceedsBalance() external givenNotNull givenBalanceNotZero {
        // Simulate the passage of time until debt becomes uncovered.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD });

        uint128 balance = flow.getBalance(defaultStreamId);

        // It should return the stream balance.
        uint128 coveredDebt = flow.coveredDebtOf(defaultStreamId);
        assertEq(coveredDebt, balance, "covered debt");
    }

    function test_WhenTotalDebtNotExceedBalance() external givenNotNull givenBalanceNotZero {
        // It should return the correct covered debt.
        uint128 coveredDebt = flow.coveredDebtOf(defaultStreamId);
        assertEq(coveredDebt, ONE_MONTH_DEBT_6D, "covered debt");
    }
}
