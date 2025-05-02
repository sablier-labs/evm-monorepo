// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract StreamedAmountOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.streamedAmountOf, ids.nullStream) });
    }

    function test_GivenCanceledStreamAndCANCELEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        lockup.cancel(ids.defaultStream);

        // It should return the correct streamed amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint256 expectedStreamedAmount = defaults.STREAMED_AMOUNT_26_PERCENT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev This test warps a second time to ensure that {streamedAmountOf} ignores the current time.
    function test_GivenCanceledStreamAndDEPLETEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        lockup.cancel(ids.defaultStream);

        // Withdraw max to deplete the stream.
        lockup.withdrawMax({ streamId: ids.defaultStream, to: users.recipient });
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() + 10 seconds });

        // It should return the correct streamed amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.STREAMED_AMOUNT_26_PERCENT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenPENDINGStatus() external givenNotNull givenNotCanceledStream {
        rewind(1 seconds);

        // It should return zero.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenSTREAMINGStatus() external givenNotNull givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should return the correct streamed amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.STREAMED_AMOUNT_26_PERCENT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenSETTLEDStatus() external givenNotNull givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // It should return the deposited amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenDEPLETEDStatus() external givenNotNull givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        // Withdraw max to deplete the stream.
        lockup.withdrawMax({ streamId: ids.defaultStream, to: users.recipient });

        // It should return the deposited amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
