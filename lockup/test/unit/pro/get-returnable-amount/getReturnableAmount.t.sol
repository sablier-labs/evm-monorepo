// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract GetReturnableAmount__Test is ProTest {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function testGetReturnableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualReturnableAmount = pro.getReturnableAmount(nonStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return the deposit amount.
    function testGetReturnableAmount__WithdrawableAmountZero__NoWithdrawals() external StreamExistent {
        uint256 actualReturnableAmount = pro.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = defaultStream.amounts.deposit;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountZero__WithWithdrawals(
        uint256 timeWarp
    ) external StreamExistent {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.startTime + timeWarp });

        // Withdraw the entire withdrawable amount.
        uint128 withdrawAmount = pro.getWithdrawableAmount(defaultStreamId);
        pro.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint256 actualReturnableAmount = pro.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = defaultStream.amounts.deposit - withdrawAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountNotZero__NoWithdrawals(
        uint256 timeWarp
    ) external StreamExistent {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.startTime + timeWarp });

        // Get the withdrawable amount.
        uint128 withdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = pro.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = defaultStream.amounts.deposit - withdrawableAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountNotZero__WithWithdrawals(
        uint256 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.startTime + timeWarp });

        // Bound the withdraw amount.
        uint128 initialWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount - 1);

        // Make the withdrawal.
        pro.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Get the withdrawable amount.
        uint128 withdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = pro.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = defaultStream.amounts.deposit - withdrawAmount - withdrawableAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}
