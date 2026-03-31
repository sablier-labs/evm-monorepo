// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {PRBMathCastingUint128 as CastingUint128} from "@prb/math/src/casting/Uint128.sol";
import {PRBMathCastingUint40 as CastingUint40} from "@prb/math/src/casting/Uint40.sol";
import {SD59x18} from "@prb/math/src/SD59x18.sol";
import {SafeOracle} from "@sablier/evm-utils/src/libraries/SafeOracle.sol";

import {LockupDynamic} from "../types/LockupDynamic.sol";
import {LockupLinear} from "../types/LockupLinear.sol";
import {LockupPriceGated} from "../types/LockupPriceGated.sol";
import {LockupTranched} from "../types/LockupTranched.sol";

/// @title LockupMath
/// @notice Provides functions for calculating the streamed amounts in Lockup streams. Note that 'streamed' is
/// synonymous with 'vested'.
library LockupMath {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the streamed amount of LD streams.
    /// @dev The LD streaming model uses the following distribution function:
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
    /// - $\Sigma(esa)$ is the sum of all streamed segments' amounts.
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
    function calculateStreamedAmountLD(
        uint128 depositedAmount,
        uint40 endTime,
        LockupDynamic.Segment[] calldata segments,
        uint40 startTime,
        uint128 withdrawnAmount
    ) external view returns (uint128) {
        uint40 blockTimestamp = uint40(block.timestamp);

        // If the start time is in the future, return zero.
        if (startTime > blockTimestamp) {
            return 0;
        }

        // If the end time is not in the future, return the deposited amount.
        if (endTime <= blockTimestamp) {
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
                previousTimestamp = startTime;
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

    /// @notice Calculates the streamed amount of LL streams.
    /// @dev The LL streaming model uses the following distribution function:
    ///
    /// $$
    /// f(x) = \begin{cases}
    ///   s, & \text{block timestamp} < \text{cliff time} \\
    ///   x * sa + s + c, & \text{block timestamp} \geq \text{cliff time}
    /// \end{cases}
    /// $$
    ///
    /// Where:
    ///
    /// - $sa$ is the streamable amount, i.e. deposited amount minus unlock amounts' sum.
    /// - $s$ is the start unlock amount.
    /// - $c$ is the cliff unlock amount.
    /// - $x$ is the elapsed time percentage with discrete unlocks:
    ///
    /// $$
    /// x = \frac{\lfloor \text{time elapsed} / \text{granularity} \rfloor * \text{granularity}}{\text{streamable time}}
    /// $$
    ///
    /// The floor division in the numerator creates discrete unlock steps at every granularity seconds.
    ///
    /// Assumptions:
    /// 1. The sum of the unlock amounts (start and cliff) does not overflow uint128 and is less than or equal to
    /// the deposit amount.
    /// 2. The start time is before the end time.
    /// 3. If the cliff time is not zero, it is after the start time and before the end time.
    /// 4. Granularity is less than or equal to the streamable range.
    /// 5. Granularity is not zero.
    function calculateStreamedAmountLL(
        uint40 cliffTime,
        uint128 depositedAmount,
        uint40 endTime,
        uint40 granularity,
        uint40 startTime,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        uint128 withdrawnAmount
    ) external view returns (uint128) {
        uint40 blockTimestamp = uint40(block.timestamp);

        // If the start time is in the future, return zero.
        if (startTime > blockTimestamp) {
            return 0;
        }

        // If the cliff time is in the future, return the start unlock amount.
        if (cliffTime > blockTimestamp) {
            return unlockAmounts.start;
        }

        // If the end time is not in the future, return the deposited amount.
        if (endTime <= blockTimestamp) {
            return depositedAmount;
        }

        unchecked {
            uint128 unlockAmountsSum = unlockAmounts.start + unlockAmounts.cliff;

            //  If the sum of the unlock amounts is greater than or equal to the deposited amount, return the deposited
            // amount. The ">=" operator is used as a safety measure in case of a bug, as the sum of the unlock amounts
            // should never exceed the deposited amount.
            if (unlockAmountsSum >= depositedAmount) {
                return depositedAmount;
            }

            // Calculate the time elapsed in granularity units as the floor division of time elapsed and unlock
            // granularity.
            uint256 elapsedTimeInGranularityUnits;

            // Calculate the streamable duration.
            uint256 streamableTotalDuration;

            if (cliffTime == 0) {
                elapsedTimeInGranularityUnits = (blockTimestamp - startTime) / granularity;
                streamableTotalDuration = uint256(endTime - startTime);
            } else {
                elapsedTimeInGranularityUnits = (blockTimestamp - cliffTime) / granularity;
                streamableTotalDuration = uint256(endTime - cliffTime);
            }

            // Calculate the streamable amount.
            uint256 streamableAmount = depositedAmount - unlockAmountsSum;

            // Calculate the streamed portion: floor(elapsed/g) * streamableAmount * g / streamableTotalDuration.
            uint256 streamedPortion =
                elapsedTimeInGranularityUnits * streamableAmount * granularity / streamableTotalDuration;

            // The streamed amount is the sum of the unlock amounts plus the streamed portion. The cast to uint128 is
            // safe because `floor(elapsed/g) * g < streamableTotalDuration`, so `streamedPortion < streamableAmount`.
            uint128 streamedAmount = unlockAmountsSum + uint128(streamedPortion);

            // Although the streamed amount should never exceed the deposited amount, this condition is checked
            // without asserting to avoid locking tokens in case of a bug. If this situation occurs, the withdrawn
            // amount is considered to be the streamed amount, and the stream is effectively frozen.
            if (streamedAmount > depositedAmount) {
                return withdrawnAmount;
            }

            return streamedAmount;
        }
    }

    /// @notice Calculates the streamed amount of LPG streams.
    /// @dev The LPG streaming model uses all-or-nothing unlock based on price threshold:
    ///
    /// $$
    /// f(x) = \begin{cases}
    ///   \text{deposited}, & \text{block timestamp} \geq \text{end time}
    ///     \lor \text{latest price} \geq \text{target price} \\
    ///   0, & \text{otherwise}
    /// \end{cases}
    /// $$
    ///
    /// Assumptions:
    /// 1. The stream is not canceled.
    /// 2. The oracle is assumed to be returning the correct price.
    function calculateStreamedAmountLPG(
        uint128 deposited,
        uint40 endTime,
        LockupPriceGated.UnlockParams memory unlockParams
    ) external view returns (uint128) {
        // If the current time is greater than or equal to the end time, return the deposited amount.
        if (block.timestamp >= endTime) {
            return deposited;
        }

        // Get the latest price, normalized to 8 decimals, from the oracle with safety checks.
        (uint128 latestPrice,,) = SafeOracle.safeOraclePrice({oracle: unlockParams.oracle, normalize: true});

        // If the oracle price is at or above the target price, return the deposited amount.
        if (latestPrice > 0 && latestPrice >= unlockParams.targetPrice) {
            return deposited;
        }

        return 0;
    }

    /// @notice Calculates the streamed amount of LT streams.
    /// @dev The LT streaming model uses the following distribution function:
    ///
    /// $$
    /// f(x) = \Sigma(eta)
    /// $$
    ///
    /// Where:
    ///
    /// - $\Sigma(eta)$ is the sum of all streamed tranches' amounts.
    ///
    /// Assumptions:
    /// 1. The sum of all tranche amounts does not overflow uint128, and equals the deposited amount.
    /// 2. The first tranche's timestamp is greater than the start time.
    /// 3. The last tranche's timestamp equals the end time.
    /// 4. The tranche timestamps are arranged in ascending order.
    function calculateStreamedAmountLT(
        uint128 depositedAmount,
        uint40 endTime,
        uint40 startTime,
        LockupTranched.Tranche[] calldata tranches
    ) external view returns (uint128) {
        uint40 blockTimestamp = uint40(block.timestamp);

        // If the start time is in the future, return zero.
        if (startTime > blockTimestamp) {
            return 0;
        }

        // If the first tranche's timestamp is in the future, return zero.
        if (tranches[0].timestamp > blockTimestamp) {
            return 0;
        }

        // If the end time is not in the future, return the deposited amount.
        if (endTime <= blockTimestamp) {
            return depositedAmount;
        }

        // Sum the amounts in all tranches that have already been streamed.
        // Using unchecked arithmetic is safe because the sum of the tranche amounts is equal to the total amount
        // at this point.
        uint128 streamedAmount = tranches[0].amount;
        uint256 tranchesCount = tranches.length;
        for (uint256 i = 1; i < tranchesCount; ++i) {
            // The loop breaks at the first tranche with a timestamp in the future. A tranche is considered streamed if
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
