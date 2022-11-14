// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD59x18 } from "@prb/math/SD59x18.sol";

import { Errors } from "./Errors.sol";

/// @title Validations
/// @notice Library with logic that checks the Sablier V2 functions' requirements.
library Validations {
    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the arguments of the `create` function in the {SablierV2Linear} contract.
    function checkCreateLinearArgs(
        address sender,
        address recipient,
        uint256 depositAmount,
        uint64 startTime,
        uint64 cliffTime,
        uint64 stopTime
    ) internal pure {
        // Checks: the common requirements for the `create` function arguments.
        _checkCreateArguments(sender, recipient, depositAmount);

        // Checks: the cliff time is greater than or equal to the start time.
        if (startTime > cliffTime) {
            revert Errors.SablierV2Linear__StartTimeGreaterThanCliffTime(startTime, cliffTime);
        }

        // Checks: the stop time is greater than or equal to the cliff time.
        if (cliffTime > stopTime) {
            revert Errors.SablierV2Linear__CliffTimeGreaterThanStopTime(cliffTime, stopTime);
        }
    }

    /// @dev Checks the arguments of the `create` function in the {SablierV2Pro} contract.
    function checkCreateProArgs(
        address sender,
        address recipient,
        uint256 depositAmount,
        uint64 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint64[] memory segmentMilestones,
        SD59x18 maxExponent,
        uint256 maxSegmentCount
    ) internal pure {
        // Checks: segment counts match.
        _checkSegmentCounts({
            amountCount: segmentAmounts.length,
            exponentCount: segmentExponents.length,
            milestoneCount: segmentMilestones.length,
            maxSegmentCount: maxSegmentCount
        });

        // We can use any count because they are all equal to each other.
        uint256 segmentCount = segmentAmounts.length;

        // Imply the stop time from the last segment milestone.
        uint64 stopTime;
        unchecked {
            stopTime = segmentMilestones[segmentCount - 1];
        }

        // Checks: the common requirements for the `create` function arguments.
        _checkCreateArguments(sender, recipient, depositAmount);

        // Checks: requirements of segments variables.
        _checkSegments(
            depositAmount,
            startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            maxExponent,
            segmentCount
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                             PRIVATE CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the basic requirements for the `create` function.
    function _checkCreateArguments(
        address sender,
        address recipient,
        uint256 depositAmount
    ) private pure {
        // Checks: the sender is not the zero address.
        if (sender == address(0)) {
            revert Errors.SablierV2__SenderZeroAddress();
        }

        // Checks: the recipient is not the zero address.
        if (recipient == address(0)) {
            revert Errors.SablierV2__RecipientZeroAddress();
        }

        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert Errors.SablierV2__DepositAmountZero();
        }
    }

    /// @dev Checks that:
    /// 1. The first milestone is greater than or equal to the start time.
    /// 2. The milestones are ordered chronologically.
    /// 3. The exponents are within the bounds permitted in Sablier.
    /// 4. The deposit amount is equal to the segment amounts summed up.
    function _checkSegments(
        uint256 depositAmount,
        uint64 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint64[] memory segmentMilestones,
        SD59x18 maxExponent,
        uint256 segmentCount
    ) private pure {
        // Check that the first milestone is greater than or equal to the start time.
        if (startTime > segmentMilestones[0]) {
            revert Errors.SablierV2Pro__StartTimeGreaterThanFirstMilestone(startTime, segmentMilestones[0]);
        }

        // Define the variables needed in the for loop below.
        uint64 currentMilestone;
        SD59x18 exponent;
        uint64 previousMilestone;
        uint256 segmentAmountsSum;

        // Iterate over the amounts, the exponents and the milestones.
        uint256 index;
        for (index = 0; index < segmentCount; ) {
            // Add the current segment amount to the sum.
            segmentAmountsSum = segmentAmountsSum + segmentAmounts[index];

            // Check that the previous milestone is less than the current milestone.
            currentMilestone = segmentMilestones[index];
            if (previousMilestone >= currentMilestone) {
                revert Errors.SablierV2Pro__SegmentMilestonesNotOrdered(index, previousMilestone, currentMilestone);
            }

            // Check that the exponent is not out of bounds.
            exponent = segmentExponents[index];
            if (exponent.gt(maxExponent)) {
                revert Errors.SablierV2Pro__SegmentExponentOutOfBounds(exponent);
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
    /// the maximum segment count permitted in Sablier.
    function _checkSegmentCounts(
        uint256 amountCount,
        uint256 exponentCount,
        uint256 milestoneCount,
        uint256 maxSegmentCount
    ) private pure {
        // Check that the amount count is not zero.
        if (amountCount == 0) {
            revert Errors.SablierV2Pro__SegmentCountZero();
        }

        // Check that the amount count is not greater than the maximum segment count permitted in Sablier.
        if (amountCount > maxSegmentCount) {
            revert Errors.SablierV2Pro__SegmentCountOutOfBounds(amountCount);
        }

        // Compare the amount count to the exponent count.
        if (amountCount != exponentCount) {
            revert Errors.SablierV2Pro__SegmentCountsNotEqual(amountCount, exponentCount, milestoneCount);
        }

        // Compare the amount count to the milestone count.
        if (amountCount != milestoneCount) {
            revert Errors.SablierV2Pro__SegmentCountsNotEqual(amountCount, exponentCount, milestoneCount);
        }
    }
}
