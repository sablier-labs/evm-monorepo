// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";
import { WithdrawableAmountOf_Unit_Test } from "../../lockup/withdrawable-amount-of/withdrawableAmountOf.t.sol";

contract WithdrawableAmountOf_Dynamic_Unit_Test is Dynamic_Unit_Test, WithdrawableAmountOf_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, WithdrawableAmountOf_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        WithdrawableAmountOf_Unit_Test.setUp();
    }

    modifier whenStatusStreaming() {
        _;
    }

    function test_WithdrawableAmountOf_StartTimeInThePresent()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    function test_WithdrawableAmountOf_NoPreviousWithdrawals()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
        whenStartTimeInThePast
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

    function test_WithdrawableAmountOf()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
        whenStartTimeInThePast
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
