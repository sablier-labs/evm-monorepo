// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD2x18, ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ud, uUNIT } from "@prb/math/UD60x18.sol";
import { arange, range } from "solidity-generators/Generators.sol";

import { Constants } from "./Constants.t.sol";
import { Lockup, LockupPro } from "src/types/DataTypes.sol";
import { Utils } from "./Utils.t.sol";

abstract contract Calculations is Constants, Utils {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Fuzzes the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
    function fuzzSegmentAmountsAndCalculateCreateAmounts(
        uint128 upperBound,
        LockupPro.Segment[] memory segments,
        UD60x18 protocolFee,
        UD60x18 brokerFee
    ) internal view returns (uint128 totalAmount, Lockup.CreateAmounts memory createAmounts) {
        uint256 segmentCount = segments.length;
        uint128 maxSegmentAmount = upperBound / uint128(segmentCount * 2);

        // Precompute the first segment amount to prevent zero deposit amounts.
        segments[0].amount = boundUint128(segments[0].amount, 100, maxSegmentAmount);
        uint128 estimatedDepositAmount = segments[0].amount;

        // Fuzz the other segment amounts by bounding from 0.
        unchecked {
            for (uint256 i = 1; i < segmentCount; ) {
                uint128 segmentAmount = boundUint128(segments[i].amount, 0, maxSegmentAmount);
                segments[i].amount = segmentAmount;
                estimatedDepositAmount += segmentAmount;
                i += 1;
            }
        }

        // Calculate the total amount from the approximated deposit amount (recall that the segment amounts summed up
        // must equal the deposit amount) using this formula:
        //
        // $$
        // total = deposit / (1e18 - protocol fee - broker fee)
        // $$
        totalAmount = ud(estimatedDepositAmount)
            .div(ud(uUNIT - protocolFee.intoUint256() - brokerFee.intoUint256()))
            .intoUint128();

        // Calculate the fee amounts.
        createAmounts.protocolFee = ud(totalAmount).mul(protocolFee).intoUint128();
        createAmounts.brokerFee = ud(totalAmount).mul(brokerFee).intoUint128();

        // Here, we account for rounding errors and adjust the estimated deposit amount and the segments. We know that
        // the estimated deposit amount is not greater than the adjusted deposit amount below, because the inverse of
        // the {Helpers-checkAndCalculateFees} function over-expresses the weight of the fees.
        createAmounts.deposit = totalAmount - createAmounts.protocolFee - createAmounts.brokerFee;
        segments[segments.length - 1].amount += (createAmounts.deposit - estimatedDepositAmount);
    }

    /// @dev Calculates the deposit amount by calculating and subtracting the protocol fee amount and the
    /// broker fee amount from the total amount.
    function calculateDepositAmount(
        uint128 totalAmount,
        UD60x18 protocolFee,
        UD60x18 brokerFee
    ) internal pure returns (uint128 depositAmount) {
        uint128 protocolFeeAmount = ud(totalAmount).mul(protocolFee).intoUint128();
        uint128 brokerFeeAmount = ud(totalAmount).mul(brokerFee).intoUint128();
        depositAmount = totalAmount - protocolFeeAmount - brokerFeeAmount;
    }

    /// @dev Helper function that replicates the logic of the {SablierV2LockupLinear-streamedAmountOf} function.
    function calculateStreamedAmount(
        uint40 currentTime,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime > DEFAULT_END_TIME) {
            return depositAmount;
        }
        unchecked {
            UD60x18 elapsedTime = ud(currentTime - DEFAULT_START_TIME);
            UD60x18 totalTime = ud(DEFAULT_TOTAL_DURATION);
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            streamedAmount = elapsedTimePercentage.mul(ud(depositAmount)).intoUint128();
        }
    }

    /// @dev Helper function that replicates the logic of the
    /// {SablierV2LockupPro-_calculateStreamedAmountForMultipleSegments} function.
    function calculateStreamedAmountForMultipleSegments(
        uint40 currentTime,
        LockupPro.Segment[] memory segments,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime >= segments[segments.length - 1].milestone) {
            return depositAmount;
        }

        unchecked {
            // Sum up the amounts found in all preceding segments.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = segments[0].milestone;
            uint256 index = 1;
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += segments[index - 1].amount;
                currentSegmentMilestone = segments[index].milestone;
                index += 1;
            }

            // After the loop exits, the current segment is found at index `index - 1`, whereas the previous segment
            // is found at `index - 2` (if there are at least two segments).
            SD59x18 currentSegmentAmount = segments[index - 1].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = segments[index - 1].exponent.intoSD59x18();
            currentSegmentMilestone = segments[index - 1].milestone;

            uint40 previousMilestone;
            if (index > 1) {
                // If the current segment is at an index that is >= 2, we use the previous segment's milestone.
                previousMilestone = segments[index - 2].milestone;
            } else {
                // Otherwise, there is only one segment, so we use the start of the stream as the previous milestone.
                previousMilestone = DEFAULT_START_TIME;
            }

            // Calculate how much time has elapsed since the segment started, and the total time of the segment.
            SD59x18 elapsedSegmentTime = (currentTime - previousMilestone).intoSD59x18();
            SD59x18 totalSegmentTime = (currentSegmentMilestone - previousMilestone).intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedSegmentTimePercentage = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = elapsedSegmentTimePercentage.pow(currentSegmentExponent);
            streamedAmount = previousSegmentAmounts + uint128(multiplier.mul(currentSegmentAmount).intoUint256());
        }
    }

    /// @dev Helper function that replicates the logic of the
    /// {SablierV2LockupPro-_calculateStreamedAmountForOneSegment} function.
    function calculateStreamedAmountForOneSegment(
        uint40 currentTime,
        UD2x18 exponent,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime >= DEFAULT_END_TIME) {
            return depositAmount;
        }
        unchecked {
            // Calculate how much time has elapsed since the stream started, and the total time of the stream.
            SD59x18 elapsedTime = (currentTime - DEFAULT_START_TIME).intoSD59x18();
            SD59x18 totalTime = DEFAULT_TOTAL_DURATION.intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            SD59x18 multiplier = elapsedTimePercentage.pow(exponent.intoSD59x18());
            streamedAmount = uint128(multiplier.mul(depositAmount.intoSD59x18()).intoUint256());
        }
    }

    /// @dev Fuzzes the deltas and updates the segment milestones.
    function fuzzSegmentDeltas(LockupPro.Segment[] memory segments) internal view returns (uint40[] memory deltas) {
        deltas = new uint40[](segments.length);
        unchecked {
            // Precompute the first segment delta.
            deltas[0] = uint40(bound(segments[0].milestone, 1, 100));
            segments[0].milestone = uint40(block.timestamp) + deltas[0];

            // Bound the deltas so that none is zero and the calculations don't overflow.
            uint256 deltaCount = deltas.length;
            uint40 maxDelta = (MAX_UNIX_TIMESTAMP - deltas[0]) / uint40(deltaCount);
            for (uint256 i = 1; i < deltaCount; ++i) {
                deltas[i] = boundUint40(segments[i].milestone, 1, maxDelta);
                segments[i].milestone = segments[i - 1].milestone + deltas[i];
            }
        }
    }

    /// @dev Fuzzes the segment milestones.
    function fuzzSegmentMilestones(LockupPro.Segment[] memory segments, uint40 startTime) internal view {
        // Precompute the first milestone so that we don't bump into an underflow in the first loop iteration.
        segments[0].milestone = startTime + 1;

        // Return here if there's only one segment to not run into division by zero.
        uint40 segmentCount = uint40(segments.length);
        if (segmentCount == 1) {
            return;
        }

        // Generate `segmentCount` milestones linearly spaced between `startTime + 1` and `MAX_UNIX_TIMESTAMP`.
        uint40 step = (MAX_UNIX_TIMESTAMP - (startTime + 1)) / (segmentCount - 1);
        uint40 halfStep = step / 2;
        uint256[] memory milestones = arange(startTime + 1, MAX_UNIX_TIMESTAMP, step);

        // Fuzz the milestone in a way that preserves its order in the array.
        for (uint256 i = 1; i < segmentCount; ) {
            uint256 milestone = milestones[i];
            milestone = bound(milestone, milestone - halfStep, milestone + halfStep);
            segments[i].milestone = uint40(milestone);
            unchecked {
                i += 1;
            }
        }
    }
}
