// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud21x18 } from "@prb/math/src/UD21x18.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract TotalDebtOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.totalDebtOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GivenPaused() external givenNotNull {
        flow.pause(defaultStreamId);

        uint128 snapshotDebt = flow.getSnapshotDebt(defaultStreamId);
        uint128 totalDebt = flow.totalDebtOf(defaultStreamId);

        assertEq(totalDebt, snapshotDebt, "total debt");
    }

    function test_WhenCurrentTimeEqualsSnapshotTime() external givenNotNull givenNotPaused {
        // Set the snapshot time to the current time by changing rate per second.
        flow.adjustRatePerSecond(defaultStreamId, ud21x18(RATE_PER_SECOND_U128 * 2));

        uint128 snapshotDebt = flow.getSnapshotDebt(defaultStreamId);
        uint128 totalDebt = flow.totalDebtOf(defaultStreamId);

        assertEq(totalDebt, snapshotDebt, "total debt");
    }

    function test_WhenCurrentTimeGreaterThanSnapshotTime() external view givenNotNull givenNotPaused {
        uint128 snapshotDebt = flow.getSnapshotDebt(defaultStreamId);
        uint128 ongoingDebt = flow.ongoingDebtOf(defaultStreamId);
        uint128 totalDebt = flow.totalDebtOf(defaultStreamId);

        assertEq(snapshotDebt + ongoingDebt, totalDebt, "total debt");
    }
}
