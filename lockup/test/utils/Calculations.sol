// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { LockupDynamic } from "../../src/types/DataTypes.sol";

import { Constants } from "./Constants.sol";

abstract contract Calculations is Constants {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;

    /// @dev Calculates the deposit amount by calculating and subtracting the protocol fee amount and the
    /// broker fee amount from the total amount.
    function calculateDepositAmount(
        uint128 totalAmount,
        UD60x18 protocolFee,
        UD60x18 brokerFee
    )
        internal
        pure
        returns (uint128 depositAmount)
    {
        uint128 protocolFeeAmount = ud(totalAmount).mul(protocolFee).intoUint128();
        uint128 brokerFeeAmount = ud(totalAmount).mul(brokerFee).intoUint128();
        depositAmount = totalAmount - protocolFeeAmount - brokerFeeAmount;
    }

    /// @dev Helper function that replicates the logic of {SablierV2LockupLinear.streamedAmountOf}.
    function calculateStreamedAmount(
        uint40 currentTime,
        uint128 depositAmount
    )
        internal
        view
        returns (uint128 streamedAmount)
    {
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

    /// @dev Helper function that replicates the logic of
    /// {SablierV2LockupDynamic-_calculateStreamedAmountForMultipleSegments}.
    function calculateStreamedAmountForMultipleSegments(
        uint40 currentTime,
        LockupDynamic.Segment[] memory segments,
        uint128 depositAmount
    )
        internal
        view
        returns (uint128 streamedAmount)
    {
        if (currentTime >= segments[segments.length - 1].milestone) {
            return depositAmount;
        }

        unchecked {
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = segments[0].milestone;
            uint256 index = 0;
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += segments[index].amount;
                index += 1;
                currentSegmentMilestone = segments[index].milestone;
            }

            SD59x18 currentSegmentAmount = segments[index].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = segments[index].exponent.intoSD59x18();
            currentSegmentMilestone = segments[index].milestone;

            uint40 previousMilestone;
            if (index > 0) {
                previousMilestone = segments[index - 1].milestone;
            } else {
                previousMilestone = DEFAULT_START_TIME;
            }

            SD59x18 elapsedSegmentTime = (currentTime - previousMilestone).intoSD59x18();
            SD59x18 totalSegmentTime = (currentSegmentMilestone - previousMilestone).intoSD59x18();

            SD59x18 elapsedSegmentTimePercentage = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = elapsedSegmentTimePercentage.pow(currentSegmentExponent);
            SD59x18 segmentStreamedAmount = multiplier.mul(currentSegmentAmount);
            streamedAmount = previousSegmentAmounts + uint128(segmentStreamedAmount.intoUint256());
        }
    }

    /// @dev Helper function that replicates the logic of
    /// {SablierV2LockupDynamic-_calculateStreamedAmountForOneSegment}.
    function calculateStreamedAmountForOneSegment(
        uint40 currentTime,
        LockupDynamic.Segment memory segment
    )
        internal
        view
        returns (uint128 streamedAmount)
    {
        if (currentTime >= segment.milestone) {
            return segment.amount;
        }
        unchecked {
            SD59x18 elapsedTime = (currentTime - DEFAULT_START_TIME).intoSD59x18();
            SD59x18 totalTime = (segment.milestone - DEFAULT_START_TIME).intoSD59x18();

            SD59x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            SD59x18 multiplier = elapsedTimePercentage.pow(segment.exponent.intoSD59x18());
            SD59x18 streamedAmountSd = multiplier.mul(segment.amount.intoSD59x18());
            streamedAmount = uint128(streamedAmountSd.intoUint256());
        }
    }
}
