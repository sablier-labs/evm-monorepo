// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, unwrap, wrap } from "@prb/math/UD60x18.sol";

import { Errors } from "./Errors.sol";

/// @title Helpers
/// @notice Library with helper functions needed across the Sablier V2 contracts.
library Helpers {
    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the protocol and the operator fee amounts.
    function checkAndCalculateFees(
        uint128 grossDepositAmount,
        UD60x18 protocolFee,
        UD60x18 operatorFee,
        UD60x18 maxFee
    ) internal pure returns (uint128 protocolFeeAmount, uint128 operatorFeeAmount, uint128 depositAmount) {
        // Checks: the protocol fee is not greater than `MAX_FEE`.
        if (protocolFee.gt(maxFee)) {
            revert Errors.SablierV2__ProtocolFeeTooHigh(protocolFee, maxFee);
        }

        // Calculate the protocol fee amount.
        protocolFeeAmount = uint128(unwrap(wrap(grossDepositAmount).mul(protocolFee)));

        // Checks: the operator fee is not greater than `MAX_FEE`.
        if (operatorFee.gt(maxFee)) {
            revert Errors.SablierV2__OperatorFeeTooHigh(operatorFee, maxFee);
        }

        // Calculate the operator fee amount.
        operatorFeeAmount = uint128(unwrap(wrap(grossDepositAmount).mul(operatorFee)));

        // Calculate the deposit amount (the amount net of fees).
        unchecked {
            assert(grossDepositAmount > protocolFeeAmount + operatorFeeAmount);
            depositAmount = grossDepositAmount - protocolFeeAmount - operatorFeeAmount;
        }
    }

    /// @dev Checks the arguments of the `create` function in the {SablierV2Linear} contract.
    function checkCreateLinearArgs(
        uint128 depositAmount,
        uint40 startTime,
        uint40 cliffTime,
        uint40 stopTime
    ) internal pure {
        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert Errors.SablierV2__GrossDepositAmountZero();
        }

        // Checks: the start time is less than or equal to the cliff time.
        if (startTime > cliffTime) {
            revert Errors.SablierV2Linear__StartTimeGreaterThanCliffTime(startTime, cliffTime);
        }

        // Checks: the cliff time is less than or equal to the stop time.
        if (cliffTime > stopTime) {
            revert Errors.SablierV2Linear__CliffTimeGreaterThanStopTime(cliffTime, stopTime);
        }
    }

    /// @dev Checks the arguments of the `create` function in the {SablierV2Pro} contract.
    function checkCreateProArgs(
        uint128 depositAmount,
        uint40 startTime,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        uint40[] memory segmentMilestones,
        uint256 maxSegmentCount
    ) internal pure {
        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert Errors.SablierV2__GrossDepositAmountZero();
        }

        // Checks: the segment counts match.
        _checkSegmentCounts({
            amountsCount: segmentAmounts.length,
            exponentsCount: segmentExponents.length,
            milestonesCount: segmentMilestones.length,
            maxSegmentCount: maxSegmentCount
        });

        // We can use any count because they are all equal to each other.
        uint256 segmentCount = segmentAmounts.length;

        // Checks: requirements of segments variables.
        _checkSegments(depositAmount, startTime, segmentAmounts, segmentMilestones, segmentCount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                             PRIVATE CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that:
    /// 1. The first milestone is greater than or equal to the start time.
    /// 2. The milestones are ordered chronologically.
    /// 3. The deposit amount is equal to the segment amounts summed up.
    function _checkSegments(
        uint128 depositAmount,
        uint40 startTime,
        uint128[] memory segmentAmounts,
        uint40[] memory segmentMilestones,
        uint256 segmentCount
    ) private pure {
        // Check that the first milestone is greater than or equal to the start time.
        if (startTime > segmentMilestones[0]) {
            revert Errors.SablierV2Pro__StartTimeGreaterThanFirstMilestone(startTime, segmentMilestones[0]);
        }

        // Define the variables needed in the for loop below.
        uint40 currentMilestone;
        uint40 previousMilestone;
        uint128 segmentAmountsSum;

        // Iterate over the amounts, the exponents and the milestones.
        uint256 index;
        for (index = 0; index < segmentCount; ) {
            // Add the current segment amount to the sum.
            segmentAmountsSum = segmentAmountsSum + segmentAmounts[index];

            // Check that the previous milestone is less than the current milestone.
            // Note: this can overflow.
            currentMilestone = segmentMilestones[index];
            if (previousMilestone >= currentMilestone) {
                revert Errors.SablierV2Pro__SegmentMilestonesNotOrdered(index, previousMilestone, currentMilestone);
            }

            // Make the current milestone the previous milestone of the next iteration.
            previousMilestone = currentMilestone;

            // Increment the for loop iterator.
            unchecked {
                index += 1;
            }
        }

        // Check that the deposit amount is equal to the segment amounts sum.
        if (depositAmount != segmentAmountsSum) {
            revert Errors.SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum(depositAmount, segmentAmountsSum);
        }
    }

    /// @dev Checks that the counts of segments match. The counts must be equal and less than or equal to
    /// the maximum segment count permitted.
    function _checkSegmentCounts(
        uint256 amountsCount,
        uint256 exponentsCount,
        uint256 milestonesCount,
        uint256 maxSegmentCount
    ) private pure {
        // Check that the amount count is not zero.
        if (amountsCount == 0) {
            revert Errors.SablierV2Pro__SegmentCountZero();
        }

        // Check that the amount count is not greater than the maximum segment count permitted.
        if (amountsCount > maxSegmentCount) {
            revert Errors.SablierV2Pro__SegmentCountOutOfBounds(amountsCount);
        }

        // Compare the amount count to the exponent count.
        if (amountsCount != exponentsCount) {
            revert Errors.SablierV2Pro__SegmentCountsNotEqual(amountsCount, exponentsCount, milestonesCount);
        }

        // Compare the amount count to the milestone count.
        if (amountsCount != milestonesCount) {
            revert Errors.SablierV2Pro__SegmentCountsNotEqual(amountsCount, exponentsCount, milestonesCount);
        }
    }
}
