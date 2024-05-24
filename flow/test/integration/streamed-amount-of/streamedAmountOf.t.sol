// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract StreamedAmountOf_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertGiven_Null() external {
        expectRevertNull();
        flow.streamedAmountOf(nullStreamId);
    }

    function test_RevertGiven_Paused() external givenNotNull {
        expectRevertPaused();
        flow.streamedAmountOf(defaultStreamId);
    }

    function test_StreamedAmountOf_LastTimeUpdateInThePresent() external view givenNotNull givenNotPaused {
        uint128 streamedAmount = flow.streamedAmountOf(defaultStreamId);
        assertEq(streamedAmount, 0, "streamed amount");
    }

    function test_StreamedAmountOf() external givenNotNull givenNotPaused {
        vm.warp({ newTimestamp: WARP_ONE_MONTH });
        uint128 streamedAmount = flow.streamedAmountOf(defaultStreamId);
        assertEq(streamedAmount, ONE_MONTH_STREAMED_AMOUNT, "streamed amount");
    }
}
