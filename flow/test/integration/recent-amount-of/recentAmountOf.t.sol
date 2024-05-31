// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract RecentAmountOf_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.recentAmountOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_RecentAmountOf_Paused() external givenNotNull {
        flow.pause(defaultStreamId);
        uint128 recentAmount = flow.recentAmountOf(defaultStreamId);
        assertEq(recentAmount, 0, "recent amount");
    }

    function test_RecentAmountOf_LastTimeUpdateInThePresent() external view givenNotNull givenNotPaused {
        uint128 recentAmount = flow.recentAmountOf(defaultStreamId);
        assertEq(recentAmount, 0, "recent amount");
    }

    function test_RecentAmountOf() external givenNotNull givenNotPaused {
        vm.warp({ newTimestamp: WARP_ONE_MONTH });
        uint128 recentAmount = flow.recentAmountOf(defaultStreamId);
        assertEq(recentAmount, ONE_MONTH_STREAMED_AMOUNT, "recent amount");
    }
}
