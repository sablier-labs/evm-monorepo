// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract WithdrawableAmountOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.withdrawableAmountOf, ids.nullStream) });
    }

    function test_GivenCanceledStreamAndCANCELEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        lockup.cancel(ids.defaultStream);

        // It should return the correct withdrawable amount.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(ids.defaultStream);
        uint256 expectedWithdrawableAmount = defaults.STREAMED_AMOUNT_26_PERCENT();
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenCanceledStreamAndDEPLETEDStatus() external givenNotNull {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        lockup.cancel(ids.defaultStream);
        lockup.withdrawMax({ streamId: ids.defaultStream, to: users.recipient });
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() + 10 seconds });

        // It should return zero.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(ids.defaultStream);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenPENDINGStatus() external givenNotNull givenNotCanceledStream {
        rewind(1 seconds);

        // It should return zero.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(ids.defaultStream);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenSETTLEDStatus() external givenNotNull givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // It should return the correct withdrawable amount.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(ids.defaultStream);
        uint128 expectedWithdrawableAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenDEPLETEDStatus() external givenNotNull givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: ids.defaultStream, to: users.recipient });

        // It should return zero.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(ids.defaultStream);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
