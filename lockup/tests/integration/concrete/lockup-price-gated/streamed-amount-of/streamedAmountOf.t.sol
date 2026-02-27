// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_PriceGated_Integration_Concrete_Test } from "../LockupPriceGated.t.sol";

contract StreamedAmountOf_Lockup_PriceGated_Integration_Concrete_Test is Lockup_PriceGated_Integration_Concrete_Test {
    function test_GivenDepletedStream() external {
        // Forward time to the end time.
        vm.warp({ newTimestamp: defaults.END_TIME() + 1 });

        // Withdraw all tokens so that the stream is depleted.
        setMsgSender(users.recipient);
        lockup.withdrawMax{ value: LOCKUP_MIN_FEE_WEI }({ streamId: ids.defaultStream, to: users.recipient });

        // It should return the deposited.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmountOf");
    }

    function test_GivenCanceledStream() external givenNotDepletedStream {
        // Cancel the stream.
        lockup.cancel(ids.defaultStream);

        // It should return zero.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmountOf");
    }

    function test_WhenEndTimeInPast()
        external
        givenNotDepletedStream
        givenNotCanceledStream
        whenLatestPriceBelowTarget
    {
        // Forward time to the end time.
        vm.warp({ newTimestamp: defaults.END_TIME() + 1 });

        // It should return the deposited.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmountOf");
    }

    function test_WhenEndTimeNotInPast()
        external
        view
        givenNotDepletedStream
        givenNotCanceledStream
        whenLatestPriceBelowTarget
    {
        // It should return zero.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmountOf");
    }

    function test_WhenLatestPriceNotBelowTarget() external givenNotDepletedStream givenNotCanceledStream {
        // Set price at target.
        oracle.setPrice(defaults.LPG_TARGET_PRICE());

        // It should return the deposited amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmountOf at target");
    }
}
