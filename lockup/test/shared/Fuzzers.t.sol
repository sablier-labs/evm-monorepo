// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/casting/Uint128.sol";
import { UD60x18, ud, uUNIT } from "@prb/math/UD60x18.sol";
import { arange } from "solidity-generators/Generators.sol";

import { Lockup, LockupDynamic } from "../../src/types/DataTypes.sol";

import { Constants } from "./Constants.t.sol";
import { Utils } from "./Utils.t.sol";

abstract contract Fuzzers is Constants, Utils {
    using CastingUint128 for uint128;

    /// @dev Just like {fuzzSegmentAmountsAndCalculateCreateAmounts} but using some defaults.
    function fuzzSegmentAmountsAndCalculateCreateAmounts(LockupDynamic.Segment[] memory segments)
        internal
        view
        returns (uint128 totalAmount, Lockup.CreateAmounts memory createAmounts)
    {
        (totalAmount, createAmounts) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: UINT128_MAX,
            segments: segments,
            protocolFee: DEFAULT_PROTOCOL_FEE,
            brokerFee: DEFAULT_BROKER_FEE
        });
    }

    /// @dev Just like {fuzzSegmentAmountsAndCalculateCreateAmounts} but using some defaults.
    function fuzzSegmentAmountsAndCalculateCreateAmounts(LockupDynamic.SegmentWithDelta[] memory segments)
        internal
        view
        returns (uint128 totalAmount, Lockup.CreateAmounts memory createAmounts)
    {
        LockupDynamic.Segment[] memory segmentsWithMilestones = getSegmentsWithMilestones(segments);
        (totalAmount, createAmounts) = fuzzSegmentAmountsAndCalculateCreateAmounts({
            upperBound: UINT128_MAX,
            segments: segmentsWithMilestones,
            protocolFee: DEFAULT_PROTOCOL_FEE,
            brokerFee: DEFAULT_BROKER_FEE
        });
        for (uint256 i = 0; i < segmentsWithMilestones.length; ++i) {
            segments[i].amount = segmentsWithMilestones[i].amount;
        }
    }

    /// @dev Fuzzes the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker
    /// fee).
    function fuzzSegmentAmountsAndCalculateCreateAmounts(
        uint128 upperBound,
        LockupDynamic.SegmentWithDelta[] memory segments,
        UD60x18 protocolFee,
        UD60x18 brokerFee
    )
        internal
        view
        returns (uint128 totalAmount, Lockup.CreateAmounts memory createAmounts)
    {
        LockupDynamic.Segment[] memory segmentsWithMilestones = getSegmentsWithMilestones(segments);
        (totalAmount, createAmounts) =
            fuzzSegmentAmountsAndCalculateCreateAmounts(upperBound, segmentsWithMilestones, protocolFee, brokerFee);
        for (uint256 i = 0; i < segmentsWithMilestones.length; ++i) {
            segments[i].amount = segmentsWithMilestones[i].amount;
        }
    }

    /// @dev Fuzzes the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker
    /// fee).
    function fuzzSegmentAmountsAndCalculateCreateAmounts(
        uint128 upperBound,
        LockupDynamic.Segment[] memory segments,
        UD60x18 protocolFee,
        UD60x18 brokerFee
    )
        internal
        view
        returns (uint128 totalAmount, Lockup.CreateAmounts memory createAmounts)
    {
        uint256 segmentCount = segments.length;
        uint128 maxSegmentAmount = upperBound / uint128(segmentCount * 2);

        // Precompute the first segment amount to prevent zero deposit amounts.
        segments[0].amount = boundUint128(segments[0].amount, 100, maxSegmentAmount);
        uint128 estimatedDepositAmount = segments[0].amount;

        // Fuzz the other segment amounts by bounding from 0.
        unchecked {
            for (uint256 i = 1; i < segmentCount; ++i) {
                uint128 segmentAmount = boundUint128(segments[i].amount, 0, maxSegmentAmount);
                segments[i].amount = segmentAmount;
                estimatedDepositAmount += segmentAmount;
            }
        }

        // Calculate the total amount from the approximated deposit amount (recall that the sum of all segment amounts
        // must equal the deposit amount) using this formula:
        //
        // $$
        // total = \frac{deposit}{1e18 - protocolFee - brokerFee}
        // $$
        totalAmount = ud(estimatedDepositAmount).div(ud(uUNIT - protocolFee.intoUint256() - brokerFee.intoUint256()))
            .intoUint128();

        // Calculate the fee amounts.
        createAmounts.protocolFee = ud(totalAmount).mul(protocolFee).intoUint128();
        createAmounts.brokerFee = ud(totalAmount).mul(brokerFee).intoUint128();

        // Here, we account for rounding errors and adjust the estimated deposit amount and the segments. We know
        // that the estimated deposit amount is not greater than the adjusted deposit amount below, because the inverse
        // of {Helpers-checkAndCalculateFees} over-expresses the weight of the fees.
        createAmounts.deposit = totalAmount - createAmounts.protocolFee - createAmounts.brokerFee;
        segments[segments.length - 1].amount += (createAmounts.deposit - estimatedDepositAmount);
    }

    /// @dev Fuzzes the deltas.
    function fuzzSegmentDeltas(LockupDynamic.SegmentWithDelta[] memory segments) internal view {
        unchecked {
            // Precompute the first segment delta.
            segments[0].delta = uint40(bound(segments[0].delta, 1, 100));

            // Bound the deltas so that none is zero and the calculations don't overflow.
            uint256 deltaCount = segments.length;
            uint40 maxDelta = (MAX_UNIX_TIMESTAMP - segments[0].delta) / uint40(deltaCount);
            for (uint256 i = 1; i < deltaCount; ++i) {
                segments[i].delta = boundUint40(segments[i].delta, 1, maxDelta);
            }
        }
    }

    /// @dev Fuzzes the segment milestones.
    function fuzzSegmentMilestones(LockupDynamic.Segment[] memory segments, uint40 startTime) internal view {
        // Return here if there's only one segment to not run into division by zero.
        uint40 segmentCount = uint40(segments.length);
        if (segmentCount == 1) {
            // The end time must not be in the past.
            segments[0].milestone = getBlockTimestamp() + 2 days;
            return;
        }

        // We precompute the first milestone so that we don't bump into an underflow in the first loop iteration. We
        // have to add 1 because the first milestone must be greater than the start time.
        segments[0].milestone = startTime + 1;

        // Generate `segmentCount` milestones linearly spaced between the first milestone and `MAX_UNIX_TIMESTAMP`.
        uint40 step = (MAX_UNIX_TIMESTAMP - segments[0].milestone) / (segmentCount - 1);
        uint40 halfStep = step / 2;
        uint256[] memory milestones = arange(segments[0].milestone, MAX_UNIX_TIMESTAMP, step);

        // Fuzz the milestones in a way that preserves their order in the array.
        for (uint256 i = 1; i < segmentCount; ++i) {
            uint256 milestone = milestones[i];
            milestone = bound(milestone, milestone - halfStep, milestone + halfStep);
            segments[i].milestone = uint40(milestone);
        }
    }
}
