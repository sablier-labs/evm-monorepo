// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { LinearTest } from "../LinearTest.t.sol";

contract GetWithdrawnAmount__Test is LinearTest {
    uint256 internal defaultStreamId;

    function setUp() public override {
        super.setUp();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should return zero.
    function testGetWithdrawnAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(nonStreamId);
        uint128 expectedWithdrawnAmount = 0;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawnAmount__NoWithdrawals(uint256 timeWarp) external StreamExistent {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.range.start + timeWarp });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = 0;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should return the correct withdrawn amount.
    function testGetWithdrawnAmount__WithWithdrawals(uint256 timeWarp, uint128 withdrawAmount) external StreamExistent {
        timeWarp = bound(timeWarp, defaultStream.range.cliff, DEFAULT_TOTAL_DURATION - 1);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.range.start + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Make the withdrawal.
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}
