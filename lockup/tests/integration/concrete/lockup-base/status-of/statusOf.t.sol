// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract StatusOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.statusOf, nullStreamId) });
    }

    function test_GivenTokensFullyWithdrawn() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // It should return DEPLETED.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenCanceledStream() external givenNotNull givenTokensNotFullyWithdrawn {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        lockup.cancel(defaultStreamId);

        // It should return CANCELED.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenStartTimeInFuture() external givenNotNull givenTokensNotFullyWithdrawn givenNotCanceledStream {
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });

        // It should return PENDING.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.PENDING;
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenZeroRefundableAmount()
        external
        givenNotNull
        givenTokensNotFullyWithdrawn
        givenNotCanceledStream
        givenStartTimeNotInFuture
    {
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // It should return SETTLED.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.SETTLED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenNonZeroRefundableAmount()
        external
        givenNotNull
        givenTokensNotFullyWithdrawn
        givenNotCanceledStream
        givenStartTimeNotInFuture
    {
        vm.warp({ newTimestamp: defaults.START_TIME() + 1 seconds });

        // It should return STREAMING.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);
    }
}
