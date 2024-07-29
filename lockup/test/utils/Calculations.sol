// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/src/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/src/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/src/SD59x18.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { LockupDynamic, LockupTranched } from "../../src/core/types/DataTypes.sol";

abstract contract Calculations {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;

    /// @dev Calculates the deposit amount by calculating and subtracting the broker fee amount from the total amount.
    function calculateDepositAmount(uint128 totalAmount, UD60x18 brokerFee) internal pure returns (uint128) {
        uint128 brokerFeeAmount = ud(totalAmount).mul(brokerFee).intoUint128();
        return totalAmount - brokerFeeAmount;
    }

    /// @dev Helper function that replicates the logic of {SablierV2LockupLinear.streamedAmountOf}.
    function calculateStreamedAmount(
        uint40 startTime,
        uint40 endTime,
        uint128 depositAmount
    )
        internal
        view
        returns (uint128)
    {
        uint40 blockTimestamp = uint40(block.timestamp);
        if (blockTimestamp >= endTime) {
            return depositAmount;
        }
        unchecked {
            UD60x18 elapsedTime = ud(blockTimestamp - startTime);
            UD60x18 totalDuration = ud(endTime - startTime);
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalDuration);
            return elapsedTimePercentage.mul(ud(depositAmount)).intoUint128();
        }
    }

    /// @dev Replicates the logic of {SablierV2LockupDynamic._calculateStreamedAmountForMultipleSegments}.
    function calculateStreamedAmountForMultipleSegments(
        LockupDynamic.Segment[] memory segments,
        uint40 startTime,
        uint128 depositAmount
    )
        internal
        view
        returns (uint128)
    {
        uint40 blockTimestamp = uint40(block.timestamp);
        if (blockTimestamp >= segments[segments.length - 1].timestamp) {
            return depositAmount;
        }

        unchecked {
            uint128 previousSegmentAmounts;
            uint40 currentSegmentTimestamp = segments[0].timestamp;
            uint256 index = 0;
            while (currentSegmentTimestamp < blockTimestamp) {
                previousSegmentAmounts += segments[index].amount;
                index += 1;
                currentSegmentTimestamp = segments[index].timestamp;
            }

            SD59x18 currentSegmentAmount = segments[index].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = segments[index].exponent.intoSD59x18();
            currentSegmentTimestamp = segments[index].timestamp;

            uint40 previousTimestamp;
            if (index > 0) {
                previousTimestamp = segments[index - 1].timestamp;
            } else {
                previousTimestamp = startTime;
            }

            SD59x18 elapsedTime = (blockTimestamp - previousTimestamp).intoSD59x18();
            SD59x18 segmentDuration = (currentSegmentTimestamp - previousTimestamp).intoSD59x18();

            SD59x18 elapsedTimePercentage = elapsedTime.div(segmentDuration);
            SD59x18 multiplier = elapsedTimePercentage.pow(currentSegmentExponent);
            SD59x18 segmentStreamedAmount = multiplier.mul(currentSegmentAmount);
            return previousSegmentAmounts + uint128(segmentStreamedAmount.intoUint256());
        }
    }

    /// @dev Replicates the logic of {SablierV2LockupDynamic._calculateStreamedAmountForOneSegment}.
    function calculateStreamedAmountForOneSegment(
        LockupDynamic.Segment memory segment,
        uint40 startTime
    )
        internal
        view
        returns (uint128)
    {
        uint40 blockTimestamp = uint40(block.timestamp);

        if (blockTimestamp >= segment.timestamp) {
            return segment.amount;
        }
        unchecked {
            SD59x18 elapsedTime = (blockTimestamp - startTime).intoSD59x18();
            SD59x18 totalDuration = (segment.timestamp - startTime).intoSD59x18();

            SD59x18 elapsedTimePercentage = elapsedTime.div(totalDuration);
            SD59x18 multiplier = elapsedTimePercentage.pow(segment.exponent.intoSD59x18());
            SD59x18 streamedAmount = multiplier.mul(segment.amount.intoSD59x18());
            return uint128(streamedAmount.intoUint256());
        }
    }

    /// @dev Helper function that replicates the logic of {SablierV2LockupTranched._calculateStreamedAmount}.
    function calculateStreamedAmountForTranches(
        LockupTranched.Tranche[] memory tranches,
        uint128 depositAmount
    )
        internal
        view
        returns (uint128)
    {
        uint40 blockTimestamp = uint40(block.timestamp);
        if (blockTimestamp >= tranches[tranches.length - 1].timestamp) {
            return depositAmount;
        }

        // Sum the amounts in all tranches that precede the block timestamp.
        uint128 streamedAmount = tranches[0].amount;
        uint40 currentTrancheTimestamp = tranches[1].timestamp;
        uint256 index = 1;

        // Using unchecked arithmetic is safe because the tranches amounts sum equal to total amount at this point.
        unchecked {
            while (currentTrancheTimestamp <= blockTimestamp) {
                streamedAmount += tranches[index].amount;
                index += 1;
                currentTrancheTimestamp = tranches[index].timestamp;
            }
        }

        return streamedAmount;
    }
}
