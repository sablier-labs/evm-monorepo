// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../Integration.t.sol";

contract DepletionTimeOf_Integration_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        // it should revert
        expectRevertNull();
        flow.depletionTimeOf(nullStreamId);
    }

    function test_RevertGiven_Paused() external givenNotNull {
        // it should revert
        expectRevertPaused();
        flow.depletionTimeOf(defaultStreamId);
    }

    function test_WhenBalanceIsZero() external view givenNotNull givenNotPaused {
        // it should return 0
        uint40 depletionTime = flow.depletionTimeOf(defaultStreamId);
        assertEq(depletionTime, 0, "depletion time");
    }

    modifier whenBalanceIsNotZero() {
        depositToDefaultStream();
        _;
    }

    function test_WhenStreamHasDebt() external givenNotNull givenNotPaused whenBalanceIsNotZero {
        vm.warp({ newTimestamp: block.timestamp + SOLVENCY_PERIOD });
        // it should return 0
        uint40 depletionTime = flow.depletionTimeOf(defaultStreamId);
        assertEq(depletionTime, 0, "depletion time");
    }

    function test_WhenStreamHasNoDebt() external givenNotNull givenNotPaused whenBalanceIsNotZero {
        // it should return the time at which the stream depletes its balance
        uint40 depletionTime = flow.depletionTimeOf(defaultStreamId);
        assertEq(depletionTime, block.timestamp + SOLVENCY_PERIOD, "depletion time");
    }
}
