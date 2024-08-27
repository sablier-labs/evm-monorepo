// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Integration_Test } from "../../Integration.t.sol";

contract OngoingDebtOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.ongoingDebtOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GivenPaused() external givenNotNull {
        flow.pause(defaultStreamId);

        // It should return zero.
        uint128 ongoingDebt = flow.ongoingDebtOf(defaultStreamId);
        assertEq(ongoingDebt, 0, "ongoing debt");
    }

    function test_WhenSnapshotTimeInPresent() external givenNotNull givenNotPaused {
        // Update the last time to the current block timestamp.
        updateSnapshotTimeToBlockTimestamp(defaultStreamId);

        // It should return zero.
        uint128 ongoingDebt = flow.ongoingDebtOf(defaultStreamId);
        assertEq(ongoingDebt, 0, "ongoing debt");
    }

    function test_WhenSnapshotTimeInPast() external view givenNotNull givenNotPaused {
        // It should return the correct ongoing debt.
        uint128 ongoingDebt = flow.ongoingDebtOf(defaultStreamId);
        assertEq(ongoingDebt, ONE_MONTH_DEBT_6D, "ongoing debt");
    }
}
