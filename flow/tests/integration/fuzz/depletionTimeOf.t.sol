// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract DepletionTimeOf_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should return a non-zero value if the current time is less than the depletion timestamp.
    /// - It should return 0 if the current time is equal to or greater than the depletion timestamp.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple streams, each with different rate per second and decimals.
    function testFuzz_DepletionTimeOf(uint256 streamId, uint8 decimals) external givenNotNull givenPaused {
        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Calculate the solvency period based on the stream deposit.
        uint256 solvencyPeriod =
            getScaledAmount(flow.getBalance(streamId) + 1, decimals) / flow.getRatePerSecond(streamId).unwrap();
        uint256 carry =
            getScaledAmount(flow.getBalance(streamId) + 1, decimals) % flow.getRatePerSecond(streamId).unwrap();

        // Assert that depletion time equals expected value.
        uint256 actualDepletionTime = flow.depletionTimeOf(streamId);
        uint256 expectedDepletionTime = carry > 0 ? OCT_1_2024 + solvencyPeriod + 1 : OCT_1_2024 + solvencyPeriod;
        assertEq(actualDepletionTime, expectedDepletionTime, "depletion time");

        // Warp time to 1 second before the depletion timestamp.
        vm.warp({ newTimestamp: actualDepletionTime - 1 });
        // Assert that total debt does not exceed the stream balance before depletion time.
        assertLe(
            flow.totalDebtOf(streamId), flow.getBalance(streamId), "pre-depletion period: total debt exceeds balance"
        );
        assertLe(flow.depletionTimeOf(streamId), getBlockTimestamp() + 1, "depletion time 1 second in future");

        // Warp time to the depletion timestamp.
        vm.warp({ newTimestamp: actualDepletionTime });
        // Assert that total debt exceeds the stream balance at depletion time.
        assertGt(
            flow.totalDebtOf(streamId),
            flow.getBalance(streamId),
            "at depletion time: total debt does not exceed balance"
        );
        assertEq(flow.depletionTimeOf(streamId), 0, "non-zero depletion time at depletion timestamp");

        // Warp time to 1 second after the depletion timestamp.
        vm.warp({ newTimestamp: actualDepletionTime + 1 });
        // Assert that total debt exceeds the stream balance after depletion time.
        assertGt(
            flow.totalDebtOf(streamId),
            flow.getBalance(streamId),
            "post-depletion time: total debt does not exceed balance"
        );
        assertEq(flow.depletionTimeOf(streamId), 0, "non-zero depletion time after depletion timestamp");
    }
}
