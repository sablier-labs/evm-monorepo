// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { LockupDynamic } from "../../src/types/LockupDynamic.sol";
import { LockupTranched } from "../../src/types/LockupTranched.sol";
import { Utils } from "./Utils.sol";

abstract contract Fuzzers is Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                   LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Just like {fuzzDynamicStreamAmounts} but with defaults.
    function fuzzDynamicStreamAmounts(LockupDynamic.Segment[] memory segments)
        internal
        pure
        returns (uint128 depositAmount)
    {
        depositAmount = fuzzDynamicStreamAmounts({ upperBound: MAX_UINT128, segments: segments });
    }

    /// @dev Just like {fuzzDynamicStreamAmounts} but with defaults.
    function fuzzDynamicStreamAmounts(LockupDynamic.SegmentWithDuration[] memory segments)
        internal
        view
        returns (uint128 depositAmount)
    {
        LockupDynamic.Segment[] memory segmentsWithTimestamps = getSegmentsWithTimestamps(segments);
        depositAmount = fuzzDynamicStreamAmounts({ upperBound: MAX_UINT128, segments: segmentsWithTimestamps });
        for (uint256 i = 0; i < segmentsWithTimestamps.length; ++i) {
            segments[i].amount = segmentsWithTimestamps[i].amount;
        }
    }

    /// @dev Fuzzes the segment amounts and calculate the deposit amount.
    function fuzzDynamicStreamAmounts(
        uint128 upperBound,
        LockupDynamic.SegmentWithDuration[] memory segments
    )
        internal
        view
        returns (uint128 depositAmount)
    {
        LockupDynamic.Segment[] memory segmentsWithTimestamps = getSegmentsWithTimestamps(segments);
        depositAmount = fuzzDynamicStreamAmounts(upperBound, segmentsWithTimestamps);
        for (uint256 i = 0; i < segmentsWithTimestamps.length; ++i) {
            segments[i].amount = segmentsWithTimestamps[i].amount;
        }
    }

    /// @dev Fuzzes the segment amounts and calculate the deposit amount.
    function fuzzDynamicStreamAmounts(
        uint128 upperBound,
        LockupDynamic.Segment[] memory segments
    )
        internal
        pure
        returns (uint128 depositAmount)
    {
        uint256 segmentCount = segments.length;
        uint128 maxSegmentAmount = upperBound / uint128(segmentCount * 2);

        // Precompute the first segment amount to prevent zero deposit amounts.
        segments[0].amount = boundUint128(segments[0].amount, 100, maxSegmentAmount);
        depositAmount = segments[0].amount;

        // Fuzz the other segment amounts by bounding from 0.
        unchecked {
            for (uint256 i = 1; i < segmentCount; ++i) {
                segments[i].amount = boundUint128(segments[i].amount, 0, maxSegmentAmount);
                depositAmount += segments[i].amount;
            }
        }
    }

    /// @dev Fuzzes the segment durations.
    function fuzzSegmentDurations(LockupDynamic.SegmentWithDuration[] memory segments) internal view {
        unchecked {
            // Precompute the first segment duration.
            segments[0].duration = uint40(_bound(segments[0].duration, 1, 100));

            // Bound the durations so that none is zero and the calculations don't overflow.
            uint256 durationCount = segments.length;
            uint40 maxDuration = (MAX_UNIX_TIMESTAMP - getBlockTimestamp()) / uint40(durationCount);
            for (uint256 i = 1; i < durationCount; ++i) {
                segments[i].duration = boundUint40(segments[i].duration, 1, maxDuration);
            }
        }
    }

    /// @dev Fuzzes the segment timestamps.
    function fuzzSegmentTimestamps(LockupDynamic.Segment[] memory segments, uint40 startTime) internal pure {
        // Return here if there's only one segment to not run into division by zero.
        uint40 segmentCount = uint40(segments.length);
        if (segmentCount == 1) {
            segments[0].timestamp = startTime + 2 days;
            return;
        }

        // The first timestamps is precomputed to avoid an underflow in the first loop iteration. We have to
        // add 1 because the first timestamp must be greater than the start time.
        segments[0].timestamp = startTime + 1 seconds;

        // Fuzz the timestamps while preserving their order in the array. For each timestamp, set its initial guess
        // as the sum of the starting timestamp and the step size multiplied by the current index. This ensures that
        // the initial guesses are evenly spaced. Next, we bound the timestamp within a range of half the step size
        // around the initial guess.
        uint256 start = segments[0].timestamp;
        uint40 step = (MAX_UNIX_TIMESTAMP - segments[0].timestamp) / (segmentCount - 1);
        uint40 halfStep = step / 2;
        for (uint256 i = 1; i < segmentCount; ++i) {
            uint256 timestamp = start + i * step;
            timestamp = _bound(timestamp, timestamp - halfStep, timestamp + halfStep);
            segments[i].timestamp = uint40(timestamp);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  LOCKUP-TRANCHED
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Fuzzes the tranche durations.
    function fuzzTrancheDurations(LockupTranched.TrancheWithDuration[] memory tranches) internal view {
        unchecked {
            // Precompute the first tranche duration.
            tranches[0].duration = uint40(_bound(tranches[0].duration, 1, 100));

            // Bound the durations so that none is zero and the calculations don't overflow.
            uint256 durationCount = tranches.length;
            uint40 maxDuration = (MAX_UNIX_TIMESTAMP - getBlockTimestamp()) / uint40(durationCount);
            for (uint256 i = 1; i < durationCount; ++i) {
                tranches[i].duration = boundUint40(tranches[i].duration, 1, maxDuration);
            }
        }
    }

    /// @dev Fuzzes the tranche timestamps.
    function fuzzTrancheTimestamps(LockupTranched.Tranche[] memory tranches, uint40 startTime) internal pure {
        // Return here if there's only one tranche to not run into division by zero.
        uint40 trancheCount = uint40(tranches.length);
        if (trancheCount == 1) {
            tranches[0].timestamp = startTime + 2 days;
            return;
        }

        // The first timestamps is precomputed to avoid an underflow in the first loop iteration. We have to
        // add 1 because the first timestamp must be greater than the start time.
        tranches[0].timestamp = startTime + 1 seconds;

        // Fuzz the timestamps while preserving their order in the array. For each timestamp, set its initial guess
        // as the sum of the starting timestamp and the step size multiplied by the current index. This ensures that
        // the initial guesses are evenly spaced. Next, we bound the timestamp within a range of half the step size
        // around the initial guess.
        uint256 start = tranches[0].timestamp;
        uint40 step = (MAX_UNIX_TIMESTAMP - tranches[0].timestamp) / (trancheCount - 1);
        uint40 halfStep = step / 2;
        for (uint256 i = 1; i < trancheCount; ++i) {
            uint256 timestamp = start + i * step;
            timestamp = _bound(timestamp, timestamp - halfStep, timestamp + halfStep);
            tranches[i].timestamp = uint40(timestamp);
        }
    }

    /// @dev Just like {fuzzTranchedStreamAmounts} but with defaults.
    function fuzzTranchedStreamAmounts(LockupTranched.Tranche[] memory tranches)
        internal
        pure
        returns (uint128 depositAmount)
    {
        depositAmount = fuzzTranchedStreamAmounts({ upperBound: MAX_UINT128, tranches: tranches });
    }

    /// @dev Just like {fuzzTranchedStreamAmounts} but with defaults.
    function fuzzTranchedStreamAmounts(LockupTranched.TrancheWithDuration[] memory tranches)
        internal
        view
        returns (uint128 depositAmount)
    {
        LockupTranched.Tranche[] memory tranchesWithTimestamps = getTranchesWithTimestamps(tranches);
        depositAmount = fuzzTranchedStreamAmounts({ upperBound: MAX_UINT128, tranches: tranchesWithTimestamps });
        for (uint256 i = 0; i < tranchesWithTimestamps.length; ++i) {
            tranches[i].amount = tranchesWithTimestamps[i].amount;
        }
    }

    /// @dev Fuzzes the tranche amounts and calculates the deposit amount.
    function fuzzTranchedStreamAmounts(
        uint128 upperBound,
        LockupTranched.TrancheWithDuration[] memory tranches
    )
        internal
        view
        returns (uint128 depositAmount)
    {
        LockupTranched.Tranche[] memory tranchesWithTimestamps = getTranchesWithTimestamps(tranches);
        depositAmount = fuzzTranchedStreamAmounts(upperBound, tranchesWithTimestamps);
        for (uint256 i = 0; i < tranchesWithTimestamps.length; ++i) {
            tranches[i].amount = tranchesWithTimestamps[i].amount;
        }
    }

    /// @dev Fuzzes the tranche amounts and calculates the deposit amount.
    function fuzzTranchedStreamAmounts(
        uint128 upperBound,
        LockupTranched.Tranche[] memory tranches
    )
        internal
        pure
        returns (uint128 depositAmount)
    {
        uint256 trancheCount = tranches.length;
        uint128 maxTrancheAmount = upperBound / uint128(trancheCount * 2);

        // Precompute the first tranche amount to prevent zero deposit amounts.
        tranches[0].amount = boundUint128(tranches[0].amount, 100, maxTrancheAmount);
        depositAmount = tranches[0].amount;

        // Fuzz the other tranche amounts by bounding from 0.
        unchecked {
            for (uint256 i = 1; i < trancheCount; ++i) {
                tranches[i].amount = boundUint128(tranches[i].amount, 0, maxTrancheAmount);
                depositAmount += tranches[i].amount;
            }
        }
    }
}
