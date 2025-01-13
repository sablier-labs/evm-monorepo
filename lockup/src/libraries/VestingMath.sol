// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/src/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/src/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/src/SD59x18.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "./../types/DataTypes.sol";

/// @title VestingMath
/// @notice Library with functions needed to calculate vested amount across lockup streams.
library VestingMath {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;

    /// @notice Calculates the streamed amount for a Lockup dynamic stream.
    /// @dev Lockup dynamic model uses the following distribution function:
    ///
    /// $$
    /// f(x) = x^{exp} * csa + \Sigma(esa)
    /// $$
    ///
    /// Where:
    ///
    /// - $x$ is the elapsed time divided by the total duration of the current segment.
    /// - $exp$ is the current segment exponent.
    /// - $csa$ is the current segment amount.
    /// - $\Sigma(esa)$ is the sum of all vested segments' amounts.
    ///
    /// Notes:
    /// 1. Normalization to 18 decimals is not needed because there is no mix of amounts with different decimals.
    /// 2. The stream's start time must be in the past so that the calculations below do not overflow.
    /// 3. The stream's end time must be in the future so that the loop below does not panic with an "index out of
    /// bounds" error.
    ///
    /// Assumptions:
    /// 1. The sum of all segment amounts does not overflow uint128 and equals the deposited amount.
    /// 2. The first segment's timestamp is greater than the start time.
    /// 3. The last segment's timestamp equals the end time.
    /// 4. The segment timestamps are arranged in ascending order.
    function calculateLockupDynamicStreamedAmount(
        uint128 depositedAmount,
        LockupDynamic.Segment[] memory segments,
        uint40 blockTimestamp,
        Lockup.Timestamps memory timestamps,
        uint128 withdrawnAmount
    )
        public
        pure
        returns (uint128)
    {
        // If the start time is in the future, return zero.
        if (timestamps.start > blockTimestamp) {
            return 0;
        }

        // If the end time is not in the future, return the deposited amount.
        if (timestamps.end <= blockTimestamp) {
            return depositedAmount;
        }

        unchecked {
            // Sum the amounts in all segments that precede the block timestamp.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentTimestamp = segments[0].timestamp;
            uint256 index = 0;
            while (currentSegmentTimestamp < blockTimestamp) {
                previousSegmentAmounts += segments[index].amount;
                index += 1;
                currentSegmentTimestamp = segments[index].timestamp;
            }

            // After exiting the loop, the current segment is at `index`.
            SD59x18 currentSegmentAmount = segments[index].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = segments[index].exponent.intoSD59x18();
            currentSegmentTimestamp = segments[index].timestamp;

            uint40 previousTimestamp;
            if (index == 0) {
                // When the current segment's index is equal to 0, the current segment is the first, so use the start
                // time as the previous timestamp.
                previousTimestamp = timestamps.start;
            } else {
                // Otherwise, when the current segment's index is greater than zero, it means that the segment is not
                // the first. In this case, use the previous segment's timestamp.
                previousTimestamp = segments[index - 1].timestamp;
            }

            // Calculate how much time has passed since the segment started, and the total duration of the segment.
            SD59x18 elapsedTime = (blockTimestamp - previousTimestamp).intoSD59x18();
            SD59x18 segmentDuration = (currentSegmentTimestamp - previousTimestamp).intoSD59x18();

            // Divide the elapsed time by the total duration of the segment.
            SD59x18 elapsedTimePercentage = elapsedTime.div(segmentDuration);

            // Calculate the streamed amount using the special formula.
            SD59x18 multiplier = elapsedTimePercentage.pow(currentSegmentExponent);
            SD59x18 segmentStreamedAmount = multiplier.mul(currentSegmentAmount);

            // Although the segment streamed amount should never exceed the total segment amount, this condition is
            // checked without asserting to avoid locking tokens in case of a bug. If this situation occurs, the
            // amount streamed in the segment is considered zero (except for past withdrawals), and the segment is
            // effectively voided.
            if (segmentStreamedAmount.gt(currentSegmentAmount)) {
                return previousSegmentAmounts > withdrawnAmount ? previousSegmentAmounts : withdrawnAmount;
            }

            // Calculate the total streamed amount by adding the previous segment amounts and the amount streamed in
            // the current segment. Casting to uint128 is safe due to the if statement above.
            return previousSegmentAmounts + uint128(segmentStreamedAmount.intoUint256());
        }
    }

    /// @notice Calculates the streamed amount for a Lockup linear stream.
    /// @dev Lockup linear model uses the following distribution function:
    ///
    /// $$
    ///        ( x * sa + s, block timestamp < cliff time
    /// f(x) = (
    ///        ( x * sa + s + c, block timestamp => cliff time
    /// $$
    ///
    /// Where:
    ///
    /// - $x$ is the elapsed time in the streamable range divided by the total streamable range.
    /// - $sa$ is the streamable amount, i.e. deposited amount minus unlock amounts' sum.
    /// - $s$ is the start unlock amount.
    /// - $c$ is the cliff unlock amount.
    ///
    /// Assumptions:
    /// 1. The sum of the unlock amounts (start and cliff) does not overflow uint128 and is less than or equal to
    /// the deposit amount.
    /// 2. The start time is before the end time.
    /// 3. If the cliff time is not zero, it is after the start time and before the end time.
    function calculateLockupLinearStreamedAmount(
        uint128 depositedAmount,
        uint40 blockTimestamp,
        Lockup.Timestamps memory timestamps,
        uint40 cliffTime,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        uint128 withdrawnAmount
    )
        public
        pure
        returns (uint128)
    {
        // If the start time is in the future, return zero.
        if (timestamps.start > blockTimestamp) {
            return 0;
        }

        // If the end time is not in the future, return the deposited amount.
        if (timestamps.end <= blockTimestamp) {
            return depositedAmount;
        }

        // If the cliff time is in the future, return the start unlock amount.
        if (cliffTime > blockTimestamp) {
            return unlockAmounts.start;
        }

        unchecked {
            uint128 unlockAmountsSum = unlockAmounts.start + unlockAmounts.cliff;

            //  If the sum of the unlock amounts is greater than or equal to the deposited amount, return the deposited
            // amount. The ">=" operator is used as a safety measure in case of a bug, as the sum of the unlock amounts
            // should never exceed the deposited amount.
            if (unlockAmountsSum >= depositedAmount) {
                return depositedAmount;
            }

            UD60x18 elapsedTime;
            UD60x18 streamableRange;

            // Calculate the streamable range.
            if (cliffTime == 0) {
                elapsedTime = ud(blockTimestamp - timestamps.start);
                streamableRange = ud(timestamps.end - timestamps.start);
            } else {
                elapsedTime = ud(blockTimestamp - cliffTime);
                streamableRange = ud(timestamps.end - cliffTime);
            }

            UD60x18 elapsedTimePercentage = elapsedTime.div(streamableRange);
            UD60x18 streamableAmount = ud(depositedAmount - unlockAmountsSum);

            // The streamed amount is the sum of the unlock amounts plus the product of elapsed time percentage and
            // streamable amount.
            uint128 streamedAmount = unlockAmountsSum + (elapsedTimePercentage.mul(streamableAmount)).intoUint128();

            // Although the streamed amount should never exceed the deposited amount, this condition is checked
            // without asserting to avoid locking tokens in case of a bug. If this situation occurs, the withdrawn
            // amount is considered to be the streamed amount, and the stream is effectively frozen.
            if (streamedAmount > depositedAmount) {
                return withdrawnAmount;
            }

            return streamedAmount;
        }
    }

    /// @notice Calculates the streamed amount for a Lockup tranched stream.
    /// @dev Lockup tranched model uses the following distribution function:
    ///
    /// $$
    /// f(x) = \Sigma(eta)
    /// $$
    ///
    /// Where:
    ///
    /// - $\Sigma(eta)$ is the sum of all vested tranches' amounts.
    ///
    /// Assumptions:
    /// 1. The sum of all tranche amounts does not overflow uint128, and equals the deposited amount.
    /// 2. The first tranche's timestamp is greater than the start time.
    /// 3. The last tranche's timestamp equals the end time.
    /// 4. The tranche timestamps are arranged in ascending order.
    function calculateLockupTranchedStreamedAmount(
        uint128 depositedAmount,
        uint40 blockTimestamp,
        Lockup.Timestamps memory timestamps,
        LockupTranched.Tranche[] memory tranches
    )
        public
        pure
        returns (uint128)
    {
        // If the start time is in the future, return zero.
        if (timestamps.start > blockTimestamp) {
            return 0;
        }

        // If the end time is not in the future, return the deposited amount.
        if (timestamps.end <= blockTimestamp) {
            return depositedAmount;
        }

        // If the first tranche's timestamp is in the future, return zero.
        if (tranches[0].timestamp > blockTimestamp) {
            return 0;
        }

        // Sum the amounts in all tranches that have already been vested.
        // Using unchecked arithmetic is safe because the sum of the tranche amounts is equal to the total amount
        // at this point.
        uint128 streamedAmount = tranches[0].amount;
        uint256 tranchesCount = tranches.length;
        for (uint256 i = 1; i < tranchesCount; ++i) {
            // The loop breaks at the first tranche with a timestamp in the future. A tranche is considered vested if
            // its timestamp is less than or equal to the block timestamp.
            if (tranches[i].timestamp > blockTimestamp) {
                break;
            }
            unchecked {
                streamedAmount += tranches[i].amount;
            }
        }

        return streamedAmount;
    }
}
