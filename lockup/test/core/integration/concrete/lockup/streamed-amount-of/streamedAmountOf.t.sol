// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { StreamedAmountOf_Integration_Shared_Test } from "../../../shared/lockup/streamedAmountOf.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract StreamedAmountOf_Integration_Concrete_Test is
    Integration_Test,
    StreamedAmountOf_Integration_Shared_Test
{
    function setUp() public virtual override(Integration_Test, StreamedAmountOf_Integration_Shared_Test) {
        StreamedAmountOf_Integration_Shared_Test.setUp();
    }

    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.streamedAmountOf(nullStreamId);
    }

    function test_GivenCanceledStreamAndCANCELEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);

        // It should return the correct streamed amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint256 expectedStreamedAmount = defaults.CLIFF_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev This test warps a second time to ensure that {streamedAmountOf} ignores the current time.
    function test_GivenCanceledStreamAndDEPLETEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);

        // Withdraw max to deplete the stream.
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() + 10 seconds });

        // It should return the correct streamed amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = defaults.CLIFF_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenPENDINGStatus() external givenNotNull givenNotCanceledStream {
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });

        // It should return zero.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenSTREAMINGStatus() external givenNotNull givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // It should return the deposited amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenDEPLETEDStatus() external givenNotNull givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        // Withdraw max to deplete the stream.
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // It should return the correct streamed amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
