// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "../types/DataTypes.sol";
import { Errors } from "./Errors.sol";

/// @title Helpers
/// @notice Library with helper functions needed across the Sablier V2 contracts.
library Helpers {
    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that neither fee is greater than `maxFee`, and then calculates the protocol fee amount, the
    /// broker fee amount, and the deposit amount from the total amount.
    function checkAndCalculateFees(
        uint128 totalAmount,
        UD60x18 protocolFee,
        UD60x18 brokerFee,
        UD60x18 maxFee
    )
        internal
        pure
        returns (Lockup.CreateAmounts memory amounts)
    {
        // When the total amount is zero, the fees are also zero.
        if (totalAmount == 0) {
            return Lockup.CreateAmounts(0, 0, 0);
        }

        // Checks: the protocol fee is not greater than `maxFee`.
        if (protocolFee.gt(maxFee)) {
            revert Errors.SablierV2Lockup_ProtocolFeeTooHigh(protocolFee, maxFee);
        }
        // Checks: the broker fee is not greater than `maxFee`.
        if (brokerFee.gt(maxFee)) {
            revert Errors.SablierV2Lockup_BrokerFeeTooHigh(brokerFee, maxFee);
        }

        // Calculate the protocol fee amount.
        // The cast to uint128 is safe because the maximum fee is hard coded.
        amounts.protocolFee = uint128(ud(totalAmount).mul(protocolFee).intoUint256());

        // Calculate the broker fee amount.
        // The cast to uint128 is safe because the maximum fee is hard coded.
        amounts.brokerFee = uint128(ud(totalAmount).mul(brokerFee).intoUint256());

        // Assert that the total amount is strictly greater than the sum of the protocol fee amount and the
        // broker fee amount.
        assert(totalAmount > amounts.protocolFee + amounts.brokerFee);

        // Calculate the deposit amount (the amount to stream, net of fees).
        amounts.deposit = totalAmount - amounts.protocolFee - amounts.brokerFee;
    }

    /// @dev Checks the parameters of the {SablierV2LockupDynamic-_createWithTimestamps} function.
    function checkCreateWithTimestamps(
        uint128 depositAmount,
        LockupDynamic.Segment[] memory segments,
        uint256 maxSegmentCount,
        uint40 startTime
    )
        internal
        view
    {
        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert Errors.SablierV2Lockup_DepositAmountZero();
        }

        // Checks: the segment count is not zero.
        uint256 segmentCount = segments.length;
        if (segmentCount == 0) {
            revert Errors.SablierV2LockupDynamic_SegmentCountZero();
        }

        // Checks: the segment count is not greater than the maximum allowed.
        if (segmentCount > maxSegmentCount) {
            revert Errors.SablierV2LockupDynamic_SegmentCountTooHigh(segmentCount);
        }

        // Checks: requirements of segments variables.
        _checkSegments(segments, depositAmount, startTime);
    }

    /// @dev Checks the parameters of the {SablierV2LockupLinear-_createWithTimestamps} function.
    function checkCreateWithTimestamps(uint128 depositAmount, LockupLinear.Range memory range) internal view {
        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert Errors.SablierV2Lockup_DepositAmountZero();
        }

        // Checks: the start time is not zero.
        if (range.start == 0) {
            revert Errors.SablierV2LockupLinear_StartTimeZero();
        }

        // Checks: the start time is strictly less than the end time.
        if (range.start >= range.end) {
            revert Errors.SablierV2LockupLinear_StartTimeNotLessThanEndTime(range.start, range.end);
        }

        // Checks: the start time is strictly less than the cliff time when cliff time is not zero.
        if (range.cliff > 0 && range.start >= range.cliff) {
            revert Errors.SablierV2LockupLinear_StartTimeNotLessThanCliffTime(range.start, range.cliff);
        }

        // Checks: the cliff time is strictly less than the end time.
        if (range.cliff >= range.end) {
            revert Errors.SablierV2LockupLinear_CliffTimeNotLessThanEndTime(range.cliff, range.end);
        }

        // Checks: the end time is in the future.
        uint40 currentTime = uint40(block.timestamp);
        if (currentTime >= range.end) {
            revert Errors.SablierV2Lockup_EndTimeNotInTheFuture(currentTime, range.end);
        }
    }

    /// @dev Checks the parameters of the {SablierV2LockupTranched-_createWithTimestamps} function.
    function checkCreateWithTimestamps(
        uint128 depositAmount,
        LockupTranched.Tranche[] memory tranches,
        uint256 maxTrancheCount,
        uint40 startTime
    )
        internal
        view
    {
        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert Errors.SablierV2Lockup_DepositAmountZero();
        }

        // Checks: the tranche count is not zero.
        uint256 trancheCount = tranches.length;
        if (trancheCount == 0) {
            revert Errors.SablierV2LockupTranched_TrancheCountZero();
        }

        // Checks: the tranche count is not greater than the maximum allowed.
        if (trancheCount > maxTrancheCount) {
            revert Errors.SablierV2LockupTranched_TrancheCountTooHigh(trancheCount);
        }

        // Checks: requirements of tranches variables.
        _checkTranches(tranches, depositAmount, startTime);
    }

    /// @dev Checks that the segment array counts match, and then adjusts the segments by calculating the timestamps.
    function checkDurationsAndCalculateTimestamps(LockupDynamic.SegmentWithDuration[] memory segments)
        internal
        view
        returns (LockupDynamic.Segment[] memory segmentsWithTimestamps)
    {
        uint256 segmentCount = segments.length;
        segmentsWithTimestamps = new LockupDynamic.Segment[](segmentCount);

        // Make the current time the stream's start time.
        uint40 startTime = uint40(block.timestamp);

        // It is safe to use unchecked arithmetic because {_createWithTimestamps} will nonetheless check the soundness
        // of the calculated segment timestamps.
        unchecked {
            // Precompute the first segment because of the need to add the start time to the first segment duration.
            segmentsWithTimestamps[0] = LockupDynamic.Segment({
                amount: segments[0].amount,
                exponent: segments[0].exponent,
                timestamp: startTime + segments[0].duration
            });

            // Copy the segment amounts and exponents, and calculate the segment timestamps.
            for (uint256 i = 1; i < segmentCount; ++i) {
                segmentsWithTimestamps[i] = LockupDynamic.Segment({
                    amount: segments[i].amount,
                    exponent: segments[i].exponent,
                    timestamp: segmentsWithTimestamps[i - 1].timestamp + segments[i].duration
                });
            }
        }
    }

    /// @dev Checks that the tranche array counts match, and then adjusts the tranches by calculating the timestamps.
    function checkDurationsAndCalculateTimestamps(LockupTranched.TrancheWithDuration[] memory tranches)
        internal
        view
        returns (LockupTranched.Tranche[] memory tranchesWithTimestamps)
    {
        uint256 trancheCount = tranches.length;
        tranchesWithTimestamps = new LockupTranched.Tranche[](trancheCount);

        // Make the current time the stream's start time.
        uint40 startTime = uint40(block.timestamp);

        // It is safe to use unchecked arithmetic because {_createWithTimestamps} will nonetheless check the soundness
        // of the calculated tranche timestamps.
        unchecked {
            // Precompute the first tranche because of the need to add the start time to the first tranche duration.
            tranchesWithTimestamps[0] =
                LockupTranched.Tranche({ amount: tranches[0].amount, timestamp: startTime + tranches[0].duration });

            // Copy the tranche amounts and calculate the tranche timestamps.
            for (uint256 i = 1; i < trancheCount; ++i) {
                tranchesWithTimestamps[i] = LockupTranched.Tranche({
                    amount: tranches[i].amount,
                    timestamp: tranchesWithTimestamps[i - 1].timestamp + tranches[i].duration
                });
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                             PRIVATE CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that:
    ///
    /// 1. The first timestamp is strictly greater than the start time.
    /// 2. The timestamps are ordered chronologically.
    /// 3. There are no duplicate timestamps.
    /// 4. The deposit amount is equal to the sum of all segment amounts.
    function _checkSegments(
        LockupDynamic.Segment[] memory segments,
        uint128 depositAmount,
        uint40 startTime
    )
        private
        view
    {
        // Checks: the start time is strictly less than the first segment timestamp.
        if (startTime >= segments[0].timestamp) {
            revert Errors.SablierV2LockupDynamic_StartTimeNotLessThanFirstSegmentTimestamp(
                startTime, segments[0].timestamp
            );
        }

        // Pre-declare the variables needed in the for loop.
        uint128 segmentAmountsSum;
        uint40 currentTimestamp;
        uint40 previousTimestamp;

        // Iterate over the segments to:
        //
        // 1. Calculate the sum of all segment amounts.
        // 2. Check that the timestamps are ordered.
        uint256 count = segments.length;
        for (uint256 index = 0; index < count; ++index) {
            // Add the current segment amount to the sum.
            segmentAmountsSum += segments[index].amount;

            // Checks: the current timestamp is strictly greater than the previous timestamp.
            currentTimestamp = segments[index].timestamp;
            if (currentTimestamp <= previousTimestamp) {
                revert Errors.SablierV2LockupDynamic_SegmentTimestampsNotOrdered(
                    index, previousTimestamp, currentTimestamp
                );
            }

            // Make the current timestamp the previous timestamp of the next loop iteration.
            previousTimestamp = currentTimestamp;
        }

        // Checks: the last timestamp is in the future.
        // When the loop exits, the current timestamp is the last timestamp, i.e. the stream's end time.
        uint40 currentTime = uint40(block.timestamp);
        if (currentTime >= currentTimestamp) {
            revert Errors.SablierV2Lockup_EndTimeNotInTheFuture(currentTime, currentTimestamp);
        }

        // Checks: the deposit amount is equal to the segment amounts sum.
        if (depositAmount != segmentAmountsSum) {
            revert Errors.SablierV2LockupDynamic_DepositAmountNotEqualToSegmentAmountsSum(
                depositAmount, segmentAmountsSum
            );
        }
    }

    /// @dev Checks that:
    ///
    /// 1. The first timestamp is strictly greater than the start time.
    /// 2. The timestamps are ordered chronologically.
    /// 3. There are no duplicate timestamps.
    /// 4. The deposit amount is equal to the sum of all tranche amounts.
    function _checkTranches(
        LockupTranched.Tranche[] memory tranches,
        uint128 depositAmount,
        uint40 startTime
    )
        private
        view
    {
        // Checks: the start time is strictly less than the first tranche timestamp.
        if (startTime >= tranches[0].timestamp) {
            revert Errors.SablierV2LockupTranched_StartTimeNotLessThanFirstTrancheTimestamp(
                startTime, tranches[0].timestamp
            );
        }

        // Pre-declare the variables needed in the for loop.
        uint128 trancheAmountsSum;
        uint40 currentTimestamp;
        uint40 previousTimestamp;

        // Iterate over the tranches to:
        //
        // 1. Calculate the sum of all tranche amounts.
        // 2. Check that the timestamps are ordered.
        uint256 count = tranches.length;
        for (uint256 index = 0; index < count; ++index) {
            // Add the current tranche amount to the sum.
            trancheAmountsSum += tranches[index].amount;

            // Checks: the current timestamp is strictly greater than the previous timestamp.
            currentTimestamp = tranches[index].timestamp;
            if (currentTimestamp <= previousTimestamp) {
                revert Errors.SablierV2LockupTranched_TrancheTimestampsNotOrdered(
                    index, previousTimestamp, currentTimestamp
                );
            }

            // Make the current timestamp the previous timestamp of the next loop iteration.
            previousTimestamp = currentTimestamp;
        }

        // Checks: the last timestamp is in the future.
        // When the loop exits, the current timestamp is the last timestamp, i.e. the stream's end time.
        uint40 currentTime = uint40(block.timestamp);
        if (currentTime >= currentTimestamp) {
            revert Errors.SablierV2Lockup_EndTimeNotInTheFuture(currentTime, currentTimestamp);
        }

        // Checks: the deposit amount is equal to the tranche amounts sum.
        if (depositAmount != trancheAmountsSum) {
            revert Errors.SablierV2LockupTranched_DepositAmountNotEqualToTrancheAmountsSum(
                depositAmount, trancheAmountsSum
            );
        }
    }
}
