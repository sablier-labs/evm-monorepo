// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract Restart_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should restart the stream.
    /// - It should update rate per second.
    /// - It should update snapshot time.
    /// - It should emit the following events: {MetadataUpdate}, {RestartFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple paused streams.
    /// - Multiple points in time.
    function testFuzz_Restart(
        uint256 streamId,
        UD21x18 ratePerSecond,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        ratePerSecond = boundRatePerSecond(ratePerSecond);

        // Pause the stream.
        flow.pause(streamId);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        uint40 warpTimestamp = getBlockTimestamp() + timeJump;

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RestartFlowStream({ streamId: streamId, sender: users.sender, ratePerSecond: ratePerSecond });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Restart the stream.
        flow.restart(streamId, ratePerSecond);

        // It should restart the stream.
        assertFalse(flow.isPaused(streamId), "isPaused");

        // It should update rate per second.
        UD21x18 actualRatePerSecond = flow.getRatePerSecond(streamId);
        assertEq(actualRatePerSecond, ratePerSecond, "ratePerSecond");

        // It should update snapshot time.
        uint40 actualSnapshotTime = flow.getSnapshotTime(streamId);
        assertEq(actualSnapshotTime, warpTimestamp, "snapshotTime");
    }
}
