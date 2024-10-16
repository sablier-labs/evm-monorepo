// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../../Integration.t.sol";

contract UncoveredDebtOf_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit into the stream.
        depositToDefaultStream();
    }

    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.uncoveredDebtOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_WhenTotalDebtNotExceedBalance() external view givenNotNull {
        // It should return zero.
        uint256 actualUncoveredDebt = flow.uncoveredDebtOf(defaultStreamId);
        assertEq(actualUncoveredDebt, 0, "uncovered debt");
    }

    function test_WhenTotalDebtExceedsBalance() external givenNotNull {
        // Simulate the passage of time to accumulate uncovered debt for one month.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + ONE_MONTH });

        uint256 totalStreamed = getDescaledAmount(RATE_PER_SECOND_U128 * (SOLVENCY_PERIOD + ONE_MONTH), 6);

        // It should return non-zero value.
        uint256 actualUncoveredDebt = flow.uncoveredDebtOf(defaultStreamId);
        uint256 expectedUncoveredDebt = totalStreamed - DEPOSIT_AMOUNT_6D;
        assertEq(actualUncoveredDebt, expectedUncoveredDebt, "uncovered debt");
    }
}
