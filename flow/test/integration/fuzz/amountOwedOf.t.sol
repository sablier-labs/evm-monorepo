// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract AmountOwedOf_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should return expected value.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple paused streams, each with different asset decimals and rps.
    /// - Multiple points in time. It includes pre-depletion and post-depletion.
    function testFuzz_Paused(uint256 streamId, uint40 timeJump, uint8 decimals) external givenNotNull {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 1 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Pause the stream.
        flow.pause(streamId);

        uint128 expectedAmountOwed = flow.amountOwedOf(streamId);

        // Simulate the passage of time after pause.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Assert that amount owed is zero.
        uint128 actualAmountOwed = flow.amountOwedOf(streamId);
        assertEq(actualAmountOwed, expectedAmountOwed, "amount owed");
    }

    /// @dev It should return the streamed balance.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-paused streams, each with different asset decimals and rps.
    /// - Multiple points in time. It includes pre-depletion and post-depletion.
    function testFuzz_AmountOwedOf(
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
        timeJump = boundUint40(timeJump, 1 seconds, 100 weeks);

        uint40 warpTimestamp = getBlockTimestamp() + timeJump;

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        // Assert that amount owed is zero.
        uint128 actualAmountOwed = flow.amountOwedOf(streamId);
        uint128 expectedAmountOwed = flow.getRatePerSecond(streamId) * (warpTimestamp - MAY_1_2024);
        assertEq(actualAmountOwed, expectedAmountOwed, "amount owed");
    }
}
