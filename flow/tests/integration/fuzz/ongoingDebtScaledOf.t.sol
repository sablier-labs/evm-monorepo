// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract OngoingDebtScaledOf_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should return the expected value.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple paused streams, each with different token decimals and rps.
    /// - Multiple points in time.
    function testFuzz_Paused(uint256 streamId, uint40 timeJump, uint8 decimals) external givenNotNull {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Pause the stream.
        flow.pause(streamId);

        uint256 expectedOngoingDebtScaled = flow.ongoingDebtScaledOf(streamId);

        // Simulate the passage of time after pause.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Assert that the ongoing debt did not change.
        uint256 actualOngoingDebtScaled = flow.ongoingDebtScaledOf(streamId);
        assertEq(actualOngoingDebtScaled, expectedOngoingDebtScaled, "ongoing debt");
    }

    /// @dev It should return 0.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-paused streams, each with different token decimals and rps.
    function testFuzz_EqualSnapshotTime(
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        givenNotNull
        givenNotPaused
    {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Update the snapshot time and warp the current block timestamp to it.
        updateSnapshotTimeAndWarp(streamId);

        // Assert that ongoing debt is zero.
        uint256 actualOngoingDebtScaled = flow.ongoingDebtScaledOf(streamId);
        assertEq(actualOngoingDebtScaled, 0, "ongoing debt");
    }

    /// @dev It should return the ongoing debt.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-paused streams, each with different token decimals and rps.
    /// - Multiple points in time after the value of snapshotTime.
    function testFuzz_OngoingDebtScaledOf(
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        givenNotNull
        givenNotPaused
    {
        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Update the snapshot time and warp the current block timestamp to it.
        updateSnapshotTimeAndWarp(streamId);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        uint128 ratePerSecond = flow.getRatePerSecond(streamId).unwrap();

        // Assert that the ongoing debt equals the expected value.
        uint256 actualOngoingDebtScaled = flow.ongoingDebtScaledOf(streamId);
        uint256 expectedOngoingDebtScaled = ratePerSecond * timeJump;
        assertEq(actualOngoingDebtScaled, expectedOngoingDebtScaled, "ongoing debt");
    }
}
