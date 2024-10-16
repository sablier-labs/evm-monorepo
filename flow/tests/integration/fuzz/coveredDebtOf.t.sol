// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract CoveredDebtOf_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should return the expected value.
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
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it is less than the depletion timestamp.
        warpTimestamp = boundUint40(warpTimestamp, getBlockTimestamp(), uint40(flow.depletionTimeOf(streamId)) - 1);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        uint256 expectedCoveredDebt = flow.coveredDebtOf(streamId);

        // Pause the stream.
        flow.pause(streamId);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: boundUint40(warpTimestamp, getBlockTimestamp() + 1, UINT40_MAX) });

        // Assert that the covered debt did not change.
        uint256 actualCoveredDebt = flow.coveredDebtOf(streamId);
        assertEq(actualCoveredDebt, expectedCoveredDebt);
    }

    /// @dev It should return the expected value.
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
        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it is less than the depletion timestamp.
        warpTimestamp = boundUint40(warpTimestamp, getBlockTimestamp(), uint40(flow.depletionTimeOf(streamId)) - 1);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        uint128 ratePerSecond = flow.getRatePerSecond(streamId).unwrap();

        // Assert that the covered debt equals the ongoing debt.
        uint256 actualCoveredDebt = flow.coveredDebtOf(streamId);
        uint256 expectedCoveredDebt = getDescaledAmount(ratePerSecond * (warpTimestamp - OCT_1_2024), decimals);
        assertEq(actualCoveredDebt, expectedCoveredDebt);
    }

    /// @dev It should return the stream balance which is also same as the deposited amount,
    /// denoted in token's decimals.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple streams, each with different token decimals and rps.
    /// - Multiple points in time post depletion period.
    function testFuzz_PostDepletion(uint256 streamId, uint40 warpTimestamp, uint8 decimals) external givenNotNull {
        (streamId,, depositedAmount) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so it is greater than depletion timestamp.
        warpTimestamp = boundUint40(warpTimestamp, uint40(flow.depletionTimeOf(streamId)) + 1, UINT40_MAX);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        // Assert that the covered debt equals the stream balance.
        uint256 actualCoveredDebt = flow.coveredDebtOf(streamId);
        assertEq(actualCoveredDebt, flow.getBalance(streamId), "covered debt vs stream balance");

        // Assert that the covered debt is same as the deposited amount.
        assertEq(actualCoveredDebt, depositedAmount, "covered debt vs deposited amount");
    }
}
