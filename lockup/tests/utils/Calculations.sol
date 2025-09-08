// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/src/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/src/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/src/SD59x18.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { LockupDynamic } from "../../src/types/LockupDynamic.sol";
import { LockupLinear } from "../../src/types/LockupLinear.sol";
import { LockupTranched } from "../../src/types/LockupTranched.sol";

abstract contract Calculations {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;

    /// @dev Replicates the logic of {LockupMath._calculateStreamedAmountLD}.
    function calculateStreamedAmountLD(
        LockupDynamic.Segment[] memory segments,
        uint40 startTime,
        uint128 depositAmount
    )
        internal
        view
        returns (uint128)
    {
        uint40 blockTimestamp = uint40(block.timestamp);

        if (startTime >= blockTimestamp) {
            return 0;
        }

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

    /// @dev Replicates the logic of {LockupMath._calculateStreamedAmountLL}.
    function calculateStreamedAmountLL(
        uint40 startTime,
        uint40 cliffTime,
        uint40 endTime,
        uint128 depositAmount,
        LockupLinear.UnlockAmounts memory unlockAmounts
    )
        internal
        view
        returns (uint128)
    {
        uint40 blockTimestamp = uint40(block.timestamp);

        if (startTime >= blockTimestamp) {
            return 0;
        }
        if (cliffTime > blockTimestamp) {
            return unlockAmounts.start;
        }
        if (blockTimestamp >= endTime) {
            return depositAmount;
        }

        unchecked {
            UD60x18 unlockAmountsSum = ud(unlockAmounts.start).add(ud(unlockAmounts.cliff));

            if (unlockAmountsSum.unwrap() >= depositAmount) {
                return depositAmount;
            }

            UD60x18 elapsedTime = cliffTime > 0 ? ud(blockTimestamp - cliffTime) : ud(blockTimestamp - startTime);
            UD60x18 streamableDuration = cliffTime > 0 ? ud(endTime - cliffTime) : ud(endTime - startTime);
            UD60x18 elapsedTimePercentage = elapsedTime.div(streamableDuration);

            UD60x18 streamableAmount = ud(depositAmount).sub(unlockAmountsSum);
            UD60x18 streamedAmount = elapsedTimePercentage.mul(streamableAmount);
            return streamedAmount.add(unlockAmountsSum).intoUint128();
        }
    }

    /// @dev Replicates the logic of {LockupMath._calculateStreamedAmountLT}.
    function calculateStreamedAmountLT(
        LockupTranched.Tranche[] memory tranches,
        uint128 depositAmount
    )
        internal
        view
        returns (uint128)
    {
        uint40 blockTimestamp = uint40(block.timestamp);

        if (tranches[0].timestamp > blockTimestamp) {
            return 0;
        }
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
