// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { GetWithdrawnAmount_Shared_Test } from "../../../shared/lockup/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { Fuzz_Test } from "../../Fuzz.t.sol";

abstract contract GetWithdrawnAmount_Fuzz_Test is Fuzz_Test, GetWithdrawnAmount_Shared_Test {
    function setUp() public virtual override(Fuzz_Test, GetWithdrawnAmount_Shared_Test) {
        GetWithdrawnAmount_Shared_Test.setUp();
    }

    function testFuzz_GetWithdrawnAmount_NoPreviousWithdrawals(uint256 timeWarp) external whenNotNull {
        timeWarp = _bound(timeWarp, 0, defaults.TOTAL_DURATION() * 2);

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.START_TIME() + timeWarp });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = 0;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function testFuzz_GetWithdrawnAmount(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenNotNull
        whenPreviousWithdrawals
    {
        timeWarp = _bound(timeWarp, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() - 1 seconds);

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.START_TIME() + timeWarp });

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
