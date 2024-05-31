// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract StreamDebtOf_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.streamDebtOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_RevertGiven_BalanceNotLessThanRemainingAmount() external givenNotNull givenPaused {
        depositToDefaultStream();
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        flow.pause(defaultStreamId);

        uint128 actualDebt = flow.streamDebtOf(defaultStreamId);
        assertEq(actualDebt, 0, "stream debt");
    }

    function test_RevertGiven_BalanceLessThanRemainingAmount() external givenNotNull givenPaused {
        uint128 depositAmount = ONE_MONTH_STREAMED_AMOUNT / 2;
        flow.deposit(defaultStreamId, depositAmount);

        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        flow.pause(defaultStreamId);

        uint128 actualDebt = flow.streamDebtOf(defaultStreamId);
        uint128 expectedDebt = ONE_MONTH_STREAMED_AMOUNT - depositAmount;
        assertEq(actualDebt, expectedDebt, "stream debt");
    }

    function test_StreamDebtOf_BalanceNotLessThanAmountOwed() external givenNotNull givenNotPaused {
        depositToDefaultStream();
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint128 actualDebt = flow.streamDebtOf(defaultStreamId);
        assertEq(actualDebt, 0, "stream debt");
    }

    function test_StreamDebtOf() external givenNotNull givenNotPaused {
        uint128 depositAmount = ONE_MONTH_STREAMED_AMOUNT / 2;
        flow.deposit(defaultStreamId, depositAmount);

        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        uint128 actualDebt = flow.streamDebtOf(defaultStreamId);
        uint128 expectedDebt = ONE_MONTH_STREAMED_AMOUNT - depositAmount;
        assertEq(actualDebt, expectedDebt, "stream debt");
    }
}
