// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract WithdrawableAmountOf_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Linear_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        linear.withdrawableAmountOf(nullStreamId);
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_StreamDepleted() external {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint256 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf_StreamCanceled() external {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        uint256 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = DEFAULT_DEPOSIT_AMOUNT - DEFAULT_RETURNED_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenStreamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_WithdrawableAmountOf_CliffTimeInTheFuture() external whenStreamActive {
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenCliffTimeInThePast() {
        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf_NoWithdrawals() external whenStreamActive whenCliffTimeInThePast {
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev it should return the correct withdrawable amount.
    function test_WithdrawableAmountOf_WithWithdrawals() external whenStreamActive whenCliffTimeInThePast {
        // Make the withdrawal.
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawableAmount = linear.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
