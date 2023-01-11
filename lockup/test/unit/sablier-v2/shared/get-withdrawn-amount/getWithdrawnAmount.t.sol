// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetWithdrawnAmount_Test is SharedTest {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        super.setUp();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should return zero.
    function test_GetWithdrawnAmount_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(nonStreamId);
        uint128 expectedWithdrawnAmount = 0;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier streamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testFuzz_GetWithdrawnAmount_NoWithdrawals(uint256 timeWarp) external streamExistent {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = 0;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should return the correct withdrawn amount.
    function testFuzz_GetWithdrawnAmount_WithWithdrawals(
        uint256 timeWarp,
        uint128 withdrawAmount
    ) external streamExistent {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_TIME, DEFAULT_TOTAL_DURATION - 1);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = sablierV2.getWithdrawableAmount(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Make the withdrawal.
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}
