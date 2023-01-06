// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetReturnableAmount_Test is SharedTest {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function test_GetReturnableAmount_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualReturnableAmount = sablierV2.getReturnableAmount(nonStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return the correct returnable amount.
    function testFuzz_GetReturnableAmount_WithdrawableAmountNotZero_NoWithdrawals(
        uint256 timeWarp
    ) external StreamExistent {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Get the withdrawable amount.
        uint128 withdrawableAmount = sablierV2.getWithdrawableAmount(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = sablierV2.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawableAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testFuzz_GetReturnableAmount_WithdrawableAmountZero_WithWithdrawals(
        uint256 timeWarp
    ) external StreamExistent {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Withdraw the entire withdrawable amount.
        uint128 withdrawAmount = sablierV2.getWithdrawableAmount(defaultStreamId);
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint256 actualReturnableAmount = sablierV2.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the deposit amount.
    function test_GetReturnableAmount_WithdrawableAmountZero_NoWithdrawals() external StreamExistent {
        uint256 actualReturnableAmount = sablierV2.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testFuzz_GetReturnableAmount_WithdrawableAmountNotZero_WithWithdrawals(
        uint256 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 initialWithdrawableAmount = sablierV2.getWithdrawableAmount(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount - 1);

        // Make the withdrawal.
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Get the withdrawable amount.
        uint128 withdrawableAmount = sablierV2.getWithdrawableAmount(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = sablierV2.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount - withdrawableAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}
