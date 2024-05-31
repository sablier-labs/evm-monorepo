// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract AmountOwedOf_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.amountOwedOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GivenPaused() external givenNotNull {
        flow.pause(defaultStreamId);

        uint128 remainingAmount = flow.getRemainingAmount(defaultStreamId);

        // It should return remaining amount
        uint128 amountOwed = flow.amountOwedOf(defaultStreamId);
        assertEq(amountOwed, remainingAmount, "amount owed");
    }

    function test_WhenCurrentTimeEqualsLastTimeUpdate() external givenNotNull givenNotPaused {
        // Update last time update to current time by changing rate per second
        flow.adjustRatePerSecond(defaultStreamId, RATE_PER_SECOND * 2);

        // Fetch updated remaining amount
        uint128 remainingAmount = flow.getRemainingAmount(defaultStreamId);

        // It should return remaining amount
        uint128 amountOwed = flow.amountOwedOf(defaultStreamId);
        assertEq(amountOwed, remainingAmount, "amount owed");
    }

    function test_WhenCurrentTimeIsGreaterThanLastTimeUpdate() external view givenNotNull givenNotPaused {
        // Fetch updated remaining amount
        uint128 remainingAmount = flow.getRemainingAmount(defaultStreamId);
        uint128 recentAmount = flow.recentAmountOf(defaultStreamId);

        // It should return the sum of remaining amount and recent amount.
        uint128 amountOwed = flow.amountOwedOf(defaultStreamId);
        assertEq(amountOwed, remainingAmount + recentAmount, "amount owed");
    }
}
