// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract RefundableAmountOf_Integration_Fuzz_Test is Integration_Test {
    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Status streaming
    /// - Status settled
    function testFuzz_RefundableAmountOf(uint256 timeJump) external {
        timeJump = _bound(timeJump, 0 seconds, defaults.TOTAL_DURATION() * 2);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Get the streamed amount.
        uint128 streamedAmount = lockup.streamedAmountOf(ids.defaultStream);

        // Run the test.
        uint256 actualRefundableAmount = lockup.refundableAmountOf(ids.defaultStream);
        uint256 expectedRefundableAmount = defaults.DEPOSIT_AMOUNT() - streamedAmount;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }
}
