// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { E, UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Broker, Segment } from "src/types/Structs.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract WithdrawableAmountOf_Pro_Unit_Test is Pro_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Pro_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier streamNotActive() {
        _;
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StreamNull() external streamNotActive {
        uint256 nullStreamId = 1729;
        uint128 actualWithdrawableAmount = pro.withdrawableAmountOf(nullStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StreamCanceled() external streamNotActive {
        lockup.cancel(defaultStreamId);
        uint256 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StreamDepleted() external streamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint256 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier streamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StartTimeGreaterThanCurrentTime() external streamActive {
        vm.warp({ timestamp: 0 });
        uint128 actualWithdrawableAmount = pro.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StartTimeEqualToCurrentTime() external streamActive {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualWithdrawableAmount = pro.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier startTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf_WithoutWithdrawals() external streamActive startTimeLessThanCurrentTime {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 3_750 seconds });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.withdrawableAmountOf(defaultStreamId);
        // The second term is 7,500*0.5^{0.5}
        uint128 expectedWithdrawableAmount = DEFAULT_SEGMENTS[0].amount + 5_303.30085889910643e18;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier withWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf() external streamActive startTimeLessThanCurrentTime withWithdrawals {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 3_750 seconds });

        // Make the withdrawal.
        pro.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.withdrawableAmountOf(defaultStreamId);

        // The second term is 7,500*0.5^{0.5}
        uint128 expectedWithdrawableAmount = DEFAULT_SEGMENTS[0].amount +
            5_303.30085889910643e18 -
            DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
