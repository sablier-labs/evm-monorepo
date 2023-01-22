// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetWithdrawableAmount_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(nullStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_CliffTimeGreaterThanCurrentTime() external streamNonNull {
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier cliffTimeLessThanOrEqualToCurrentTime() {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_GetWithdrawableAmount_NoWithdrawals() external streamNonNull cliffTimeLessThanOrEqualToCurrentTime {
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return the correct withdrawable amount.
    function test_GetWithdrawableAmount_WithWithdrawals() external streamNonNull cliffTimeLessThanOrEqualToCurrentTime {
        // Make the withdrawal.
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
