// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../../Integration.t.sol";

contract StreamDebtOf_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit into the stream.
        depositDefaultAmountToDefaultStream();
    }

    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.streamDebtOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_WhenAmountOwedDoesNotExceedBalance() external view givenNotNull {
        // It should return zero.
        uint128 actualDebt = flow.streamDebtOf(defaultStreamId);
        assertEq(actualDebt, 0, "stream debt");
    }

    function test_WhenAmountOwedExceedsBalance() external givenNotNull {
        // Simulate the passage of time to accumulate debt for one month.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + ONE_MONTH });

        uint128 totalStreamed = RATE_PER_SECOND * (SOLVENCY_PERIOD + ONE_MONTH);

        // It should return non-zero value.
        uint128 actualDebt = flow.streamDebtOf(defaultStreamId);
        uint128 expectedDebt = totalStreamed - DEPOSIT_AMOUNT;
        assertEq(actualDebt, expectedDebt, "stream debt");
    }
}
