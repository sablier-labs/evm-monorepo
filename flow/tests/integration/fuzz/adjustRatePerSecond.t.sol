// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract AdjustRatePerSecond_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should revert.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for ratePerSecond.
    /// - Multiple paused streams, each with different rate per second and decimals.
    /// - Multiple points in time to adjust the rate per second.
    function testFuzz_RevertGiven_Paused(
        uint256 streamId,
        UD21x18 newRatePerSecond,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        newRatePerSecond = ud21x18(boundUint128(newRatePerSecond.unwrap(), 1, UINT128_MAX));

        // Make the stream paused.
        flow.pause(streamId);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        uint256 previousTotalDebt = flow.totalDebtOf(streamId);

        // Expect the relevant error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_StreamPaused.selector, streamId));

        // Adjust the rate per second.
        flow.adjustRatePerSecond(streamId, newRatePerSecond);

        assertEq(flow.ongoingDebtScaledOf(streamId), 0, "ongoing debt");

        assertEq(previousTotalDebt, flow.totalDebtOf(streamId), "rate per second");
    }

    /// @dev Checklist:
    /// - It should adjust rate per second.
    /// - It should emit the following events: {AdjustFlowStream}, {MetadataUpdate}.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for ratePerSecond.
    /// - Multiple non-paused streams, each with different rate per second and decimals.
    /// - Multiple points in time to adjust the rate per second.
    function testFuzz_AdjustRatePerSecond(
        uint256 streamId,
        UD21x18 newRatePerSecond,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
    {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        newRatePerSecond = ud21x18(boundUint128(newRatePerSecond.unwrap(), 1, UINT128_MAX));

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        uint256 previousTotalDebt = flow.totalDebtOf(streamId);

        UD21x18 currentRatePerSecond = flow.getRatePerSecond(streamId);
        if (newRatePerSecond.unwrap() == currentRatePerSecond.unwrap()) {
            // Expect the relevant error.
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierFlow_RatePerSecondNotDifferent.selector, streamId, newRatePerSecond
                )
            );
        } else {
            // Expect the relevant events to be emitted.
            vm.expectEmit({ emitter: address(flow) });
            emit ISablierFlow.AdjustFlowStream({
                streamId: streamId,
                totalDebt: flow.totalDebtOf(streamId),
                oldRatePerSecond: currentRatePerSecond,
                newRatePerSecond: newRatePerSecond
            });

            vm.expectEmit({ emitter: address(flow) });
            emit IERC4906.MetadataUpdate({ _tokenId: streamId });
        }

        // Adjust the rate per second.
        flow.adjustRatePerSecond(streamId, newRatePerSecond);

        assertEq(flow.ongoingDebtScaledOf(streamId), 0, "ongoing debt");

        assertEq(previousTotalDebt, flow.totalDebtOf(streamId), "rate per second");
    }
}
