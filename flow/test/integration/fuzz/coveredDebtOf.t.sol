// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract CoveredDebtOf_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should return the expected value.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple paused streams, each with different token decimals and rps.
    /// - Multiple points in time prior to depletion period.
    function testFuzz_PreDepletion_Paused(uint256 streamId, uint40 timeJump, uint8 decimals) external givenNotNull {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        uint40 depletionPeriod = flow.depletionTimeOf(streamId);

        // Bound the time jump so that it exceeds depletion timestamp.
        timeJump = boundUint40(timeJump, getBlockTimestamp(), depletionPeriod);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        uint128 expectedCoveredDebt = flow.coveredDebtOf(streamId);

        // Pause the stream.
        flow.pause(streamId);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: uint256(getBlockTimestamp()) + uint256(timeJump) });

        // Assert that the covered debt did not change.
        uint128 actualCoveredDebt = flow.coveredDebtOf(streamId);
        assertEq(actualCoveredDebt, expectedCoveredDebt);
    }

    /// @dev It should return the expected value.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-paused streams, each with different token decimals and rps.
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
        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        uint40 depletionPeriod = flow.depletionTimeOf(streamId);

        // Bound the time jump so that it exceeds depletion timestamp.
        timeJump = boundUint40(timeJump, getBlockTimestamp(), depletionPeriod);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Assert that the covered debt equals the ongoing debt.
        uint128 actualCoveredDebt = flow.coveredDebtOf(streamId);
        uint128 expectedCoveredDebt =
            getDenormalizedAmount(flow.getRatePerSecond(streamId).unwrap() * (timeJump - MAY_1_2024), decimals);
        assertEq(actualCoveredDebt, expectedCoveredDebt);
    }

    /// @dev It should return the stream balance which is also same as the deposited amount,
    /// denoted in token's decimals.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple streams, each with different token decimals and rps.
    /// - Multiple points in time post depletion period.
    function testFuzz_PostDepletion(uint256 streamId, uint40 timeJump, uint8 decimals) external givenNotNull {
        (streamId,, depositedAmount) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it exceeds depletion timestamp.
        uint40 depletionPeriod = flow.depletionTimeOf(streamId);
        timeJump = boundUint40(timeJump, depletionPeriod + 1, UINT40_MAX);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Assert that the covered debt equals the stream balance.
        uint128 actualCoveredDebt = flow.coveredDebtOf(streamId);
        assertEq(actualCoveredDebt, flow.getBalance(streamId), "covered debt vs stream balance");

        // Assert that the covered debt is same as the deposited amount.
        assertEq(actualCoveredDebt, depositedAmount, "covered debt vs deposited amount");
    }
}
