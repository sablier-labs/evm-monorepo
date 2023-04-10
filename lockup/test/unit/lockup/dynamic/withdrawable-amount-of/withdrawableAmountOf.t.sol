// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract WithdrawableAmountOf_Dynamic_Unit_Test is Dynamic_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Dynamic_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        dynamic.withdrawableAmountOf(nullStreamId);
    }

    function test_WithdrawableAmountOf_StreamDepleted() external {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint256 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_WithdrawableAmountOf_StreamCanceled() external {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        uint256 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = DEFAULT_DEPOSIT_AMOUNT - DEFAULT_RETURNED_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenStreamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_WithdrawableAmountOf_StartTimeInTheFuture() external whenStreamActive {
        vm.warp({ timestamp: 0 });
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_WithdrawableAmountOf_StartTimeInThePresent() external whenStreamActive {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    function test_WithdrawableAmountOf_WithoutWithdrawals() external whenStreamActive whenStartTimeInThePast {
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

    function test_WithdrawableAmountOf() external whenStreamActive whenStartTimeInThePast whenWithWithdrawals {
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
