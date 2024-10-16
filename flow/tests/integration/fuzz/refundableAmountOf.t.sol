// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract RefundableAmountOf_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should return the refundable amount equal to the deposited amount, denoted in token's decimals.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple paused streams, each with different token decimals and rps.
    /// - Multiple points in time prior to depletion period.
    function testFuzz_PreDepletion_Paused(
        uint256 streamId,
        uint40 warpTimestamp,
        uint8 decimals
    )
        external
        givenNotNull
    {
        (streamId,, depositedAmount) = useFuzzedStreamOrCreate(streamId, decimals);

        uint40 depletionPeriod = uint40(flow.depletionTimeOf(streamId));

        // Pause the stream.
        flow.pause(streamId);

        uint128 previousStreamBalance = flow.getBalance(streamId);

        // Bound the time jump so that it is less than the depletion timestamp.
        warpTimestamp = boundUint40(warpTimestamp, getBlockTimestamp(), depletionPeriod - 1);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        // Assert that the refundable amount equals the stream balance before the time warp.
        uint128 actualRefundableAmount = flow.refundableAmountOf(streamId);
        assertEq(actualRefundableAmount, previousStreamBalance);

        // Assert that the refundable amount is same as the deposited amount.
        assertEq(actualRefundableAmount, depositedAmount);
    }

    /// @dev It should return the refundable amount equal to the deposited amount minus streamed amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-paused streams, each with different token decimals and rps.
    /// - Multiple points in time prior to depletion period.
    function testFuzz_PreDepletion(
        uint256 streamId,
        uint40 warpTimestamp,
        uint8 decimals
    )
        external
        givenNotNull
        givenNotPaused
    {
        (streamId, decimals, depositedAmount) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it is less than the depletion timestamp.
        warpTimestamp = boundUint40(warpTimestamp, getBlockTimestamp(), uint40(flow.depletionTimeOf(streamId)) - 1);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        uint128 ratePerSecond = flow.getRatePerSecond(streamId).unwrap();

        // Assert that the refundable amount same as the deposited amount minus streamed amount.
        uint256 actualRefundableAmount = flow.refundableAmountOf(streamId);
        uint256 expectedRefundableAmount =
            depositedAmount - getDescaledAmount(ratePerSecond * (warpTimestamp - OCT_1_2024), decimals);
        assertEq(actualRefundableAmount, expectedRefundableAmount);
    }

    /// @dev It should return the zero value for refundable amount.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple streams, each with different token decimals and rps.
    /// - Multiple points in time post depletion period.
    function testFuzz_PostDepletion(uint256 streamId, uint40 warpTimestamp, uint8 decimals) external givenNotNull {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so it is greater than depletion timestamp.
        uint40 depletionPeriod = uint40(flow.depletionTimeOf(streamId));
        warpTimestamp = boundUint40(warpTimestamp, depletionPeriod + 1, UINT40_MAX);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        // Assert that the refundable amount is zero.
        uint256 actualRefundableAmount = flow.refundableAmountOf(streamId);
        assertEq(actualRefundableAmount, 0);
    }
}
