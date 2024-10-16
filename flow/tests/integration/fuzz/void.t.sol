// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract Void_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should revert.
    /// - It should pause the stream.
    /// - It should set rate per second to 0.
    /// - It should set ongoing debt to 0 and keep the total debt unchanged.
    /// - It should emit the following events: {MetadataUpdate}, {VoidFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Only two values for caller (stream owner and approved operator).
    /// - Multiple non-paused streams, each with different token decimals and rps.
    /// - Multiple points in time pre depletion timestamp.
    function testFuzz_RevertWhen_PreDepletion(
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
    {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it does not exceed depletion timestamp.
        uint40 depletionTime = uint40(flow.depletionTimeOf(streamId));
        timeJump = boundUint40(timeJump, getBlockTimestamp(), depletionTime);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Prank to either recipient or operator.
        resetPrank({ msgSender: useRecipientOrOperator(streamId, timeJump) });

        // Void the stream.
        flow.void(streamId);
    }

    /// @dev Checklist:
    /// - It should pause the stream.
    /// - It should set rate per second to 0.
    /// - It should set ongoing debt to 0, uncovered debt to 0, and total debt to the stream balance.
    /// - It should emit the following events: {MetadataUpdate}, {VoidFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Only two values for caller (stream owner and approved operator).
    /// - Multiple paused streams, each with different token decimals and rps.
    /// - Multiple points in time post depletion timestamp.
    function testFuzz_Paused(
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        (streamId,, depositedAmount) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it exceeds depletion timestamp.
        uint40 depletionTime = uint40(flow.depletionTimeOf(streamId));
        timeJump = boundUint40(timeJump, depletionTime + 1, UINT40_MAX);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Pause the stream.
        flow.pause(streamId);

        // Prank to either recipient or operator.
        address caller = useRecipientOrOperator(streamId, timeJump);
        resetPrank({ msgSender: caller });

        // Void the stream.
        _test_Void(caller, streamId);
    }

    /// @dev Checklist:
    /// - It should pause the stream.
    /// - It should set rate per second to 0.
    /// - It should set ongoing debt to 0, uncovered debt to 0, and total debt to the stream balance.
    /// - It should emit the following events: {MetadataUpdate}, {VoidFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Only two values for caller (stream owner and approved operator).
    /// - Multiple non-paused streams, each with different token decimals and rps.
    /// - Multiple points in time post depletion timestamp.
    function testFuzz_Void(
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
    {
        (streamId,, depositedAmount) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it exceeds depletion timestamp.
        uint40 depletionTime = uint40(flow.depletionTimeOf(streamId));
        timeJump = boundUint40(timeJump, depletionTime + 1, UINT40_MAX);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Prank to either recipient or operator.
        address caller = useRecipientOrOperator(streamId, timeJump);
        resetPrank({ msgSender: caller });

        // Void the stream.
        _test_Void(caller, streamId);
    }

    // Shared private function.
    function _test_Void(address caller, uint256 streamId) private {
        uint256 debtToWriteOff = flow.uncoveredDebtOf(streamId);
        uint128 expectedTotalDebt;

        if (debtToWriteOff > 0) {
            // Expect the total debt to be the stream balance if there is uncovered debt.
            expectedTotalDebt = flow.getBalance(streamId);
        } else {
            // Otherwise, expect the total debt to remain same.
            expectedTotalDebt = uint128(flow.totalDebtOf(streamId));
        }

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.VoidFlowStream({
            streamId: streamId,
            recipient: users.recipient,
            sender: users.sender,
            caller: caller,
            newTotalDebt: expectedTotalDebt,
            writtenOffDebt: debtToWriteOff
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Void the stream.
        flow.void(streamId);

        // Assert the checklist.
        assertTrue(flow.isVoided(streamId), "voided");
        assertTrue(flow.isPaused(streamId), "paused");
        assertEq(flow.getRatePerSecond(streamId), 0, "rate per second");
        assertEq(flow.ongoingDebtScaledOf(streamId), 0, "ongoing debt");
        assertEq(flow.uncoveredDebtOf(streamId), 0, "uncovered debt");
        assertEq(flow.totalDebtOf(streamId), expectedTotalDebt, "total debt");
    }
}
