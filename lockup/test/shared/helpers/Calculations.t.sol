// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD2x18, ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Constants } from "./Constants.t.sol";
import { Segment } from "src/types/Structs.sol";

abstract contract Calculations is Constants {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Adjust the amounts in the default segments as two fractions of the provided net deposit amount,
    /// one 20%, the other 80%.
    function adjustSegmentAmounts(Segment[] memory segments, uint128 netDepositAmount) internal pure {
        segments[0].amount = ud(netDepositAmount).mul(ud(0.2e18)).intoUint128();
        segments[1].amount = netDepositAmount - segments[0].amount;
    }

    /// @dev Helper function that replicates the logic of the {SablierV2LockupLinear-getStreamedAmount} function.
    function calculateStreamedAmount(
        uint40 currentTime,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime > DEFAULT_STOP_TIME) {
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
        Segment[] memory segments,
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
        if (currentTime >= DEFAULT_STOP_TIME) {
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
}
