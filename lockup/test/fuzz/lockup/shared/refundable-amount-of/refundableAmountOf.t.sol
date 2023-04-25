// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract RefundableAmountOf_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        defaultStreamId = createDefaultStream();
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Status streaming
    /// - Status settled
    function testFuzz_RefundableAmountOf(uint256 timeWarp) external {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Get the streamed amount.
        uint128 streamedAmount = lockup.streamedAmountOf(defaultStreamId);

        // Run the test.
        uint256 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint256 expectedRefundableAmount = DEFAULT_DEPOSIT_AMOUNT - streamedAmount;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }
}
