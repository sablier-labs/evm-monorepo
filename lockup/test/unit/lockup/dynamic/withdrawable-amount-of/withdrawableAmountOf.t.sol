// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract WithdrawableAmountOf_Dynamic_Unit_Test is Dynamic_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Dynamic_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenStreamNotActive() {
        _;
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StreamNull() external whenStreamNotActive {
        uint256 nullStreamId = 1729;
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(nullStreamId);
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
    function test_WithdrawableAmountOf_StartTimeGreaterThanCurrentTime() external whenStreamActive {
        vm.warp({ timestamp: 0 });
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StartTimeEqualToCurrentTime() external whenStreamActive {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenStartTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf_WithoutWithdrawals()
        external
        whenStreamActive
        whenStartTimeLessThanCurrentTime
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 3750 seconds });

        // Run the test.
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);
        // The second term is 7,500*0.5^{0.5}
        uint128 expectedWithdrawableAmount = DEFAULT_SEGMENTS[0].amount + 5303.30085889910643e18;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenWithWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf()
        external
        whenStreamActive
        whenStartTimeLessThanCurrentTime
        whenWithWithdrawals
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 3750 seconds });

        // Make the withdrawal.
        dynamic.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);

        // The second term is 7,500*0.5^{0.5}
        uint128 expectedWithdrawableAmount =
            DEFAULT_SEGMENTS[0].amount + 5303.30085889910643e18 - DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
