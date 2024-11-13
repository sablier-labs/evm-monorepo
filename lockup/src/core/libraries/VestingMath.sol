// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/src/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/src/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/src/SD59x18.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { LockupDynamic, LockupTranched } from "./../types/DataTypes.sol";

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
    function calculateLockupDynamicStreamedAmount(
        LockupDynamic.Segment[] memory segments,
        uint40 startTime,
        uint128 withdrawnAmount
    )
        public
        view
        returns (uint128)
    {
        unchecked {
            uint40 blockTimestamp = uint40(block.timestamp);

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
            // checked without asserting to avoid locking assets in case of a bug. If this situation occurs, the
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
    /// f(x) = x * d + c
    /// $$
    ///
    /// Where:
    ///
    /// - $x$ is the elapsed time divided by the stream's total duration.
    /// - $d$ is the deposited amount.
    /// - $c$ is the cliff amount.
    function calculateLockupLinearStreamedAmount(
        uint128 depositedAmount,
        uint40 startTime,
        uint40 cliffTime,
        uint40 endTime,
        uint128 withdrawnAmount
    )
        public
        view
        returns (uint128)
    {
        uint256 blockTimestamp = block.timestamp;

        // If the cliff time is in the future, return zero.
        if (cliffTime > blockTimestamp) {
            return 0;
        }

        // In all other cases, calculate the amount streamed so far. Normalization to 18 decimals is not needed
        // because there is no mix of amounts with different decimals.
        unchecked {
            // Calculate how much time has passed since the stream started, and the stream's total duration.
            UD60x18 elapsedTime = ud(blockTimestamp - startTime);
            UD60x18 totalDuration = ud(endTime - startTime);

            // Divide the elapsed time by the stream's total duration.
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalDuration);

            // Cast the deposited amount to UD60x18.
            UD60x18 depositedAmountUD60x18 = ud(depositedAmount);

            // Calculate the streamed amount by multiplying the elapsed time percentage by the deposited amount.
            UD60x18 streamedAmount = elapsedTimePercentage.mul(depositedAmountUD60x18);

            // Although the streamed amount should never exceed the deposited amount, this condition is checked
            // without asserting to avoid locking assets in case of a bug. If this situation occurs, the withdrawn
            // amount is considered to be the streamed amount, and the stream is effectively frozen.
            if (streamedAmount.gt(depositedAmountUD60x18)) {
                return withdrawnAmount;
            }

            // Cast the streamed amount to uint128. This is safe due to the check above.
            return uint128(streamedAmount.intoUint256());
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
    function calculateLockupTranchedStreamedAmount(LockupTranched.Tranche[] memory tranches)
        public
        view
        returns (uint128)
    {
        uint256 blockTimestamp = block.timestamp;

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
