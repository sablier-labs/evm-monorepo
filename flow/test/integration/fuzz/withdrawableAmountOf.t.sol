// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract WithdrawbleAmountOf_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should return the expected value.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple paused streams, each with different asset decimals and rps.
    /// - Multiple points in time prior to depletion period.
    function testFuzz_PreDepletion_Paused(uint256 streamId, uint40 timeJump, uint8 decimals) external givenNotNull {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        uint40 depletionPeriod = flow.depletionTimeOf(streamId);

        // Bound the time jump so that it exceeds depletion timestamp.
        timeJump = boundUint40(timeJump, getBlockTimestamp(), depletionPeriod);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        uint128 expectedWithdrawbleAmount = flow.withdrawableAmountOf(streamId);

        // Pause the stream.
        flow.pause(streamId);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Assert that the withdrawble amount equals 0.
        uint128 actualWithdrawbleAmount = flow.withdrawableAmountOf(streamId);
        assertEq(actualWithdrawbleAmount, expectedWithdrawbleAmount);
    }

    /// @dev It should return the streamed amount, denoted in 18 decimals.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-paused streams, each with different asset decimals and rps.
    /// - Multiple points in time prior to depletion period.
    function testFuzz_PreDepletion(
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        givenNotNull
        givenNotPaused
    {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        uint40 depletionPeriod = flow.depletionTimeOf(streamId);

        // Bound the time jump so that it exceeds depletion timestamp.
        timeJump = boundUint40(timeJump, getBlockTimestamp(), depletionPeriod);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Assert that the withdrawble amount equals the streamed amount.
        uint128 actualWithdrawbleAmount = flow.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawbleAmount = flow.getRatePerSecond(streamId) * (timeJump - MAY_1_2024);
        assertEq(actualWithdrawbleAmount, expectedWithdrawbleAmount);
    }

    /// @dev It should return the stream balance which is also same as the deposited amount, denoted in 18 decimals.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple streams, each with different asset decimals and rps.
    /// - Multiple points in time post depletion period.
    function testFuzz_PostDepletion(uint256 streamId, uint40 timeJump, uint8 decimals) external givenNotNull {
        (streamId,, depositedAmount) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it exceeds depletion timestamp.
        uint40 depletionPeriod = flow.depletionTimeOf(streamId);
        timeJump = boundUint40(timeJump, depletionPeriod + 1, UINT40_MAX);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Assert that the withdrawble amount equals the stream balance.
        uint128 actualWithdrawbleAmount = flow.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawbleAmount = flow.getBalance(streamId);
        assertEq(actualWithdrawbleAmount, expectedWithdrawbleAmount);

        // Assert that the withdrawble amount is same as the deposited amount.
        assertEq(actualWithdrawbleAmount, depositedAmount);
    }
}
