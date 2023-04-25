// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../Fuzz.t.sol";

abstract contract GetWithdrawnAmount_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        changePrank({ msgSender: users.recipient });
    }

    modifier whenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function testFuzz_GetWithdrawnAmount_NoPreviousWithdrawals(uint256 timeWarp) external whenNotNull {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = 0;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenPreviousWithdrawals() {
        _;
    }

    function testFuzz_GetWithdrawnAmount(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenNotNull
        whenPreviousWithdrawals
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

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
