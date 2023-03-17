// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Linear_Unit_Test } from "../Linear.t.sol";

contract WithdrawableAmountOf_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Linear_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenStreamNotActive() {
        _;
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StreamNull() external whenStreamNotActive {
        uint256 nullStreamId = 1729;
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(nullStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StreamCanceled() external whenStreamNotActive {
        lockup.cancel(defaultStreamId);
        uint256 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StreamDepleted() external whenStreamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint256 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenStreamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_CliffTimeGreaterThanCurrentTime() external whenStreamActive {
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenCliffTimeLessThanOrEqualToCurrentTime() {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf_NoWithdrawals()
        external
        whenStreamActive
        whenCliffTimeLessThanOrEqualToCurrentTime
    {
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf_WithWithdrawals()
        external
        whenStreamActive
        whenCliffTimeLessThanOrEqualToCurrentTime
    {
        // Make the withdrawal.
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
