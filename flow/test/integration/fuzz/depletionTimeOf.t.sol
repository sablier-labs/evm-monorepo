// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract DepletionTimeOf_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should return 0 if the time has already passed the solvency period.
    /// - It should return a non-zero value if the time has not yet passed the solvency period.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple streams, each with different rate per second and decimals.
    /// - Multiple points in time, both pre-depletion and post-depletion.
    function testFuzz_DepletionTimeOf(
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        givenNotNull
        givenPaused
    {
        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Calculate the solvency period based on the stream deposit.
        uint40 solvencyPeriod =
            uint40(getNormalizedAmount(flow.getBalance(streamId), decimals) / flow.getRatePerSecond(streamId));

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 1 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Assert that depletion time equals expected value.
        uint40 actualDepletionTime = flow.depletionTimeOf(streamId);
        if (getBlockTimestamp() > MAY_1_2024 + solvencyPeriod) {
            assertEq(actualDepletionTime, 0, "depletion time");
        } else {
            assertEq(actualDepletionTime, MAY_1_2024 + solvencyPeriod, "depletion time");
        }
    }
}
