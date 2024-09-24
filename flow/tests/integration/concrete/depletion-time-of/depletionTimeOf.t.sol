// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../../Integration.t.sol";

contract DepletionTimeOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.depletionTimeOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Paused() external givenNotNull {
        bytes memory callData = abi.encodeCall(flow.depletionTimeOf, defaultStreamId);
        expectRevert_Paused(callData);
    }

    function test_GivenBalanceZero() external view givenNotNull givenNotPaused {
        // It should return 0
        uint40 depletionTime = flow.depletionTimeOf(defaultStreamId);
        assertEq(depletionTime, 0, "depletion time");
    }

    function test_GivenUncoveredDebt() external givenNotNull givenNotPaused givenBalanceNotZero {
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD });
        // It should return 0
        uint40 depletionTime = flow.depletionTimeOf(defaultStreamId);
        assertEq(depletionTime, 0, "depletion time");
    }

    function test_GivenNoUncoveredDebt() external givenNotNull givenNotPaused givenBalanceNotZero {
        // It should return the time at which the stream depletes its balance
        uint40 depletionTime = flow.depletionTimeOf(defaultStreamId);
        assertEq(depletionTime, WARP_SOLVENCY_PERIOD, "depletion time");
    }
}
